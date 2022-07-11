local a,b,c,d=(function(e)local f={[{}]=true}local g;local h={}local require;local i={}g=function(j,k)if not h[j]then h[j]=k end end;require=function(j)local l=i[j]if l then if l==f then return nil end else if not h[j]then if not e then local m=type(j)=='string'and'\"'..j..'\"'or tostring(j)error('Tried to require '..m..', but no such module has been registered')else return e(j)end end;i[j]=f;l=h[j](require,i,g,h)i[j]=l end;return l end;return require,i,g,h end)(require)c("__root",function(require,n,c,d)function plugindef()finaleplugin.RequireSelection=false;finaleplugin.HandlesUndo=true;finaleplugin.Author="Robert Patterson"finaleplugin.Copyright="CC0 https://creativecommons.org/publicdomain/zero/1.0/"finaleplugin.Version="1.1"finaleplugin.Date="January 20, 2022"finaleplugin.CategoryTags="Note"finaleplugin.Notes=[[
        This script allows you to specify a number of chromatic steps by which to transpose and the script
        simplifies the spelling. Chromatic steps are half-steps in a standard 12-tone scale, but they are smaller
        if you are using a microtone sytem defined in a custom key signature.

        Normally the script opens a modeless window. However, if you invoke the plugin with a shift, option, or
        alt key pressed, it skips opening a window and uses the last settings you entered into the window.
        (This works with RGP Lua version 0.60 and higher.)
        
        If you are using custom key signatures with JW Lua or an early version of RGP Lua, you must create
        a custom_key_sig.config.txt file in a folder called `script_settings` within the same folder as the script.
        It should contains the following two lines that define the custom key signature you are using. Unfortunately,
        the JW Lua and early versions of RGP Lua do not allow scripts to read this information from the Finale document.
        
        (This example is for 31-EDO.)
        
        ```
        number_of_steps = 31
        diatonic_steps = {0, 5, 10, 13, 18, 23, 28}
        ```
        
        Later versions of RGP Lua (0.58 or higher) ignore this configuration file (if it exists) and read the correct
        information from the Finale document.
    ]]return"Transpose By Steps...","Transpose By Steps","Transpose by the number of steps given, simplifying spelling as needed."end;global_dialog=nil;global_number_of_steps_edit=nil;local o=false;if not finenv.RetainLuaState then context={number_of_steps=nil,window_pos_x=nil,window_pos_y=nil}end;if not finenv.IsRGPLua then local p=finale.FCString()p:SetRunningLuaFolderPath()package.path=package.path..";"..p.LuaString.."?.lua"end;local q=require("library.transposition")function do_transpose_by_step(global_number_of_steps_edit)if finenv.Region():IsEmpty()then return end;local r="Transpose By Steps "..tostring(finenv.Region().StartMeasure)if finenv.Region().StartMeasure~=finenv.Region().EndMeasure then r=r.." - "..tostring(finenv.Region().EndMeasure)end;local s=true;finenv.StartNewUndoBlock(r,false)for t in eachentrysaved(finenv.Region())do for u in each(t)do if not q.stepwise_transpose(u,global_number_of_steps_edit)then s=false end end end;if finenv.EndUndoBlock then finenv.EndUndoBlock(true)finenv.Region():Redraw()else finenv.StartNewUndoBlock(r,true)end;if not s then finenv.UI():AlertError("Finale is unable to represent some of the transposed pitches. These pitches were left at their original value.","Transposition Error")end;return s end;function create_dialog_box()local v=finale.FCString()local w=finale.FCCustomLuaWindow()v.LuaString="Transpose By Steps"w:SetTitle(v)local x=0;local y=105;local z=w:CreateStatic(0,x+2)v.LuaString="Number Of Steps:"z:SetText(v)local A=y;if finenv.UI():IsOnMac()then A=A+4 end;global_number_of_steps_edit=w:CreateEdit(A,x)if context.number_of_steps and 0~=context.number_of_steps then local v=finale.FCString()v:AppendInteger(context.number_of_steps)global_number_of_steps_edit:SetText(v)end;w:CreateOkButton()w:CreateCancelButton()if w.OkButtonCanClose then w.OkButtonCanClose=o end;return w end;function on_ok()do_transpose_by_step(global_number_of_steps_edit:GetInteger())end;function on_close()if global_dialog:QueryLastCommandModifierKeys(finale.CMDMODKEY_ALT)or global_dialog:QueryLastCommandModifierKeys(finale.CMDMODKEY_SHIFT)then finenv.RetainLuaState=false else context.number_of_steps=global_number_of_steps_edit:GetInteger()global_dialog:StorePosition()context.window_pos_x=global_dialog.StoredX;context.window_pos_y=global_dialog.StoredY end end;function transpose_by_step()o=finenv.QueryInvokedModifierKeys and(finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT)or finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT))if o and context.number_of_steps then do_transpose_by_step(context.number_of_steps)return end;global_dialog=create_dialog_box()if nil~=context.window_pos_x and nil~=context.window_pos_y then global_dialog:StorePosition()global_dialog:SetRestorePositionOnlyData(context.window_pos_x,context.window_pos_y)global_dialog:RestorePosition()end;global_dialog:RegisterHandleOkButtonPressed(on_ok)if global_dialog.RegisterCloseWindow then global_dialog:RegisterCloseWindow(on_close)end;if finenv.IsRGPLua then if nil~=finenv.RetainLuaState then finenv.RetainLuaState=true end;finenv.RegisterModelessDialog(global_dialog)global_dialog:ShowModeless()else if finenv.Region():IsEmpty()then finenv.UI():AlertInfo("Please select a music region before running this script.","Selection Required")return end;global_dialog:ExecuteModal(nil)end end;transpose_by_step()end)c("library.transposition",function(require,n,c,d)local B={}function B.finale_version(C,D,E)local F=bit32.bor(bit32.lshift(math.floor(C),24),bit32.lshift(math.floor(D),20))if E then F=bit32.bor(F,math.floor(E))end;return F end;function B.group_overlaps_region(G,H)if H:IsFullDocumentSpan()then return true end;local I=false;local J=finale.FCSystemStaves()J:LoadAllForRegion(H)for K in each(J)do if G:ContainsStaff(K:GetStaff())then I=true;break end end;if not I then return false end;if G.StartMeasure>H.EndMeasure or G.EndMeasure<H.StartMeasure then return false end;return true end;function B.group_is_contained_in_region(G,H)if not H:IsStaffIncluded(G.StartStaff)then return false end;if not H:IsStaffIncluded(G.EndStaff)then return false end;return true end;function B.staff_group_is_multistaff_instrument(G)local L=finale.FCMultiStaffInstruments()L:LoadAll()for M in each(L)do if M:ContainsStaff(G.StartStaff)and M.GroupID==G:GetItemID()then return true end end;return false end;function B.get_selected_region_or_whole_doc()local N=finenv.Region()if N:IsEmpty()then N:SetFullDocument()end;return N end;function B.get_first_cell_on_or_after_page(O)local P=O;local Q=finale.FCPage()local R=false;while Q:Load(P)do if Q:GetFirstSystem()>0 then R=true;break end;P=P+1 end;if R then local S=finale.FCStaffSystem()S:Load(Q:GetFirstSystem())return finale.FCCell(S.FirstMeasure,S.TopStaff)end;local T=finale.FCMusicRegion()T:SetFullDocument()return finale.FCCell(T.EndMeasure,T.EndStaff)end;function B.get_top_left_visible_cell()if not finenv.UI():IsPageView()then local U=finale.FCMusicRegion()U:SetFullDocument()return finale.FCCell(finenv.UI():GetCurrentMeasure(),U.StartStaff)end;return B.get_first_cell_on_or_after_page(finenv.UI():GetCurrentPage())end;function B.get_top_left_selected_or_visible_cell()local N=finenv.Region()if not N:IsEmpty()then return finale.FCCell(N.StartMeasure,N.StartStaff)end;return B.get_top_left_visible_cell()end;function B.is_default_measure_number_visible_on_cell(V,W,X,Y)local Z=finale.FCCurrentStaffSpec()if not Z:LoadForCell(W,0)then return false end;if V:GetShowOnTopStaff()and W.Staff==X.TopStaff then return true end;if V:GetShowOnBottomStaff()and W.Staff==X:CalcBottomStaff()then return true end;if Z.ShowMeasureNumbers then return not V:GetExcludeOtherStaves(Y)end;return false end;function B.is_default_number_visible_and_left_aligned(V,W,_,Y,a0)if V.UseScoreInfoForParts then Y=false end;if a0 and V:GetShowOnMultiMeasureRests(Y)then if finale.MNALIGN_LEFT~=V:GetMultiMeasureAlignment(Y)then return false end elseif W.Measure==_.FirstMeasure then if not V:GetShowOnSystemStart()then return false end;if finale.MNALIGN_LEFT~=V:GetStartAlignment(Y)then return false end else if not V:GetShowMultiples(Y)then return false end;if finale.MNALIGN_LEFT~=V:GetMultipleAlignment(Y)then return false end end;return B.is_default_measure_number_visible_on_cell(V,W,_,Y)end;function B.update_layout(a1,a2)a1=a1 or 1;a2=a2 or false;local a3=finale.FCPage()if a3:Load(a1)then a3:UpdateLayout(a2)end end;function B.get_current_part()local a4=finale.FCParts()a4:LoadAll()return a4:GetCurrent()end;function B.get_page_format_prefs()local a5=B.get_current_part()local a6=finale.FCPageFormatPrefs()local s=false;if a5:IsScore()then s=a6:LoadScore()else s=a6:LoadParts()end;return a6,s end;local a7=function(a8)local a9=finenv.UI():IsOnWindows()local aa=function(ab,ac)if finenv.UI():IsOnWindows()then return ab and os.getenv(ab)or""else return ac and os.getenv(ac)or""end end;local ad=a8 and aa("LOCALAPPDATA","HOME")or aa("COMMONPROGRAMFILES")if not a9 then ad=ad.."/Library/Application Support"end;ad=ad.."/SMuFL/Fonts/"return ad end;function B.get_smufl_font_list()local ae={}local af=function(a8)local ad=a7(a8)local ag=function()if finenv.UI():IsOnWindows()then return io.popen('dir "'..ad..'" /b /ad')else return io.popen('ls "'..ad..'"')end end;local ah=function(ai)local aj=finale.FCString()aj.LuaString=ai;return finenv.UI():IsFontAvailable(aj)end;for ai in ag():lines()do if not ai:find("%.")then ai=ai:gsub(" Bold","")ai=ai:gsub(" Italic","")local aj=finale.FCString()aj.LuaString=ai;if ae[ai]or ah(ai)then ae[ai]=a8 and"user"or"system"end end end end;af(true)af(false)return ae end;function B.get_smufl_metadata_file(ak)if not ak then ak=finale.FCFontInfo()ak:LoadFontPrefs(finale.FONTPREF_MUSIC)end;local al=function(am,ak)local an=am..ak.Name.."/"..ak.Name..".json"return io.open(an,"r")end;local ao=al(a7(true),ak)if ao then return ao end;return al(a7(false),ak)end;function B.is_font_smufl_font(ak)if not ak then ak=finale.FCFontInfo()ak:LoadFontPrefs(finale.FONTPREF_MUSIC)end;if finenv.RawFinaleVersion>=B.finale_version(27,1)then if nil~=ak.IsSMuFLFont then return ak.IsSMuFLFont end end;local ap=B.get_smufl_metadata_file(ak)if nil~=ap then io.close(ap)return true end;return false end;function B.simple_input(aq,ar)local as=finale.FCString()as.LuaString=""local v=finale.FCString()local at=160;function format_ctrl(au,av,aw,ax)au:SetHeight(av)au:SetWidth(aw)v.LuaString=ax;au:SetText(v)end;title_width=string.len(aq)*6+54;if title_width>at then at=title_width end;text_width=string.len(ar)*6;if text_width>at then at=text_width end;v.LuaString=aq;local w=finale.FCCustomLuaWindow()w:SetTitle(v)local ay=w:CreateStatic(0,0)format_ctrl(ay,16,at,ar)local az=w:CreateEdit(0,20)format_ctrl(az,20,at,"")w:CreateOkButton()w:CreateCancelButton()function callback(au)end;w:RegisterHandleCommand(callback)if w:ExecuteModal(nil)==finale.EXECMODAL_OK then as.LuaString=az:GetText(as)return as.LuaString end end;function B.is_finale_object(aA)return aA and type(aA)=="userdata"and aA.ClassName and aA.GetClassID and true or false end;function B.system_indent_set_to_prefs(_,a6)a6=a6 or B.get_page_format_prefs()local aB=finale.FCMeasure()local aC=_.FirstMeasure==1;if not aC and aB:Load(_.FirstMeasure)then if aB.ShowFullNames then aC=true end end;if aC and a6.UseFirstSystemMargins then _.LeftMargin=a6.FirstSystemLeft else _.LeftMargin=a6.SystemLeft end;return _:Save()end;function B.calc_script_name(aD)local aE=finale.FCString()if finenv.RunningLuaFilePath then aE.LuaString=finenv.RunningLuaFilePath()else aE:SetRunningLuaFilePath()end;local aF=finale.FCString()aE:SplitToPathAndFile(nil,aF)local F=aF.LuaString;if not aD then F=F:match("(.+)%..+")if not F or F==""then F=aF.LuaString end end;return F end;return B end)return a("__root")