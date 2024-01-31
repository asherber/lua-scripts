import fs from 'fs'
import path from 'path'
import { getAllImports, getFileParts } from './helpers'
import { resolveRequiredFile } from './lua-require'
import { removeComments } from './remove-comments'
import { wrapImport } from './wrap-import'
import { injectExtras } from './inject-extras';

export type ImportedFile = {
    dependencies: string[]
    wrapped: string
}

export type ImportedFiles = Record<string, ImportedFile | undefined>

export const files: ImportedFiles = {}

export const importFileBase = (name: string, importedFiles: ImportedFiles, fetcher: (name: string) => string) => {
    try {
        if (name in importedFiles) return true
        const contents = fetcher(resolveRequiredFile(name))
        importedFiles[name] = {
            dependencies: getAllImports(contents),
            wrapped: wrapImport(name, contents),
        }
        return true
    } catch {
        return false
    }
}

export const bundleFileBase = (
    name: string,
    importedFiles: ImportedFiles,
    mixins: string[],
    fetcher: (name: string) => string
) => {
    const fileContents = injectExtras(name, fetcher(name))
    const fileStack: string[] = [fileContents]
    const importStack: string[] = getAllImports(fileContents)
    const importedFileNames = new Set<string>()

    while (importStack.length > 0) {
        const nextImport = importStack.pop() ?? ''
        if (importedFileNames.has(nextImport)) continue

        const fileFound = importFileBase(nextImport, importedFiles, fetcher)
        if (fileFound) {
            const file = importedFiles[nextImport]
            importedFileNames.add(nextImport)
            if (file) {
                importStack.push(...file.dependencies)
                fileStack.push(file.wrapped)
            }
            if (resolveRequiredFile(nextImport) === 'library/mixin.lua') importStack.push(...mixins)
        } else {
            console.error(`Unresolvable import in file "${name}": ${nextImport}`)
            process.exitCode = 1
        }
    }

    return fileStack.reverse().join('\n\n')
}

export const bundleFile = (name: string, sourcePath: string, mixins: string[]): string => {
    const bundled: string = bundleFileBase(name, files, mixins, (fileName: string) =>
            fs.readFileSync(path.join(sourcePath, fileName)).toString()
        );
    const parts = getFileParts(bundled);

    return removeComments(parts.prolog, true) 
        + removeComments(parts.plugindef, false) 
        + removeComments(parts.epilog, true);
}
