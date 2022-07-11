local a,b,c,d=(function(e)local f={[{}]=true}local g;local h={}local require;local i={}g=function(j,k)if not h[j]then h[j]=k end end;require=function(j)local l=i[j]if l then if l==f then return nil end else if not h[j]then if not e then local m=type(j)=='string'and'\"'..j..'\"'or tostring(j)error('Tried to require '..m..', but no such module has been registered')else return e(j)end end;i[j]=f;l=h[j](require,i,g,h)i[j]=l end;return l end;return require,i,g,h end)(require)c("__root",function(require,n,c,d)function plugindef()finaleplugin.RequireSelection=true;finaleplugin.Author="Nick Mazuk"finaleplugin.Copyright="CC0 https://creativecommons.org/publicdomain/zero/1.0/"finaleplugin.Version="1.0"finaleplugin.Date="August 22, 2021"finaleplugin.CategoryTags="Accidental"finaleplugin.AuthorURL="https://nickmazuk.com"return"Simplify accidentals","Simplify accidentals","Removes all double sharps and flats by respelling them"end;local o=require("library.transposition")function accidentals_simplify()for p in eachentrysaved(finenv.Region())do if not p:IsNote()then goto q end;local r=p.Measure;local s=p.Staff;local t=finale.FCCell(r,s)local u=t:GetKeySignature()for v in each(p)do if v.RaiseLower==0 then goto w end;local x=finale.FCString()v:GetString(x,u,false,false)local y=x:GetLuaString()if string.match(y,"bb")or string.match(y,"##")then o.enharmonic_transpose(v,v.RaiseLower)o.chromatic_transpose(v,0,0,true)end::w::end::q::end end;accidentals_simplify()end)c("library.transposition",function(require,n,c,d)local z={}function z.finale_version(A,B,C)local D=bit32.bor(bit32.lshift(math.floor(A),24),bit32.lshift(math.floor(B),20))if C then D=bit32.bor(D,math.floor(C))end;return D end;function z.group_overlaps_region(E,F)if F:IsFullDocumentSpan()then return true end;local G=false;local H=finale.FCSystemStaves()H:LoadAllForRegion(F)for I in each(H)do if E:ContainsStaff(I:GetStaff())then G=true;break end end;if not G then return false end;if E.StartMeasure>F.EndMeasure or E.EndMeasure<F.StartMeasure then return false end;return true end;function z.group_is_contained_in_region(E,F)if not F:IsStaffIncluded(E.StartStaff)then return false end;if not F:IsStaffIncluded(E.EndStaff)then return false end;return true end;function z.staff_group_is_multistaff_instrument(E)local J=finale.FCMultiStaffInstruments()J:LoadAll()for K in each(J)do if K:ContainsStaff(E.StartStaff)and K.GroupID==E:GetItemID()then return true end end;return false end;function z.get_selected_region_or_whole_doc()local L=finenv.Region()if L:IsEmpty()then L:SetFullDocument()end;return L end;function z.get_first_cell_on_or_after_page(M)local N=M;local O=finale.FCPage()local P=false;while O:Load(N)do if O:GetFirstSystem()>0 then P=true;break end;N=N+1 end;if P then local Q=finale.FCStaffSystem()Q:Load(O:GetFirstSystem())return finale.FCCell(Q.FirstMeasure,Q.TopStaff)end;local R=finale.FCMusicRegion()R:SetFullDocument()return finale.FCCell(R.EndMeasure,R.EndStaff)end;function z.get_top_left_visible_cell()if not finenv.UI():IsPageView()then local S=finale.FCMusicRegion()S:SetFullDocument()return finale.FCCell(finenv.UI():GetCurrentMeasure(),S.StartStaff)end;return z.get_first_cell_on_or_after_page(finenv.UI():GetCurrentPage())end;function z.get_top_left_selected_or_visible_cell()local L=finenv.Region()if not L:IsEmpty()then return finale.FCCell(L.StartMeasure,L.StartStaff)end;return z.get_top_left_visible_cell()end;function z.is_default_measure_number_visible_on_cell(T,t,U,V)local W=finale.FCCurrentStaffSpec()if not W:LoadForCell(t,0)then return false end;if T:GetShowOnTopStaff()and t.Staff==U.TopStaff then return true end;if T:GetShowOnBottomStaff()and t.Staff==U:CalcBottomStaff()then return true end;if W.ShowMeasureNumbers then return not T:GetExcludeOtherStaves(V)end;return false end;function z.is_default_number_visible_and_left_aligned(T,t,X,V,Y)if T.UseScoreInfoForParts then V=false end;if Y and T:GetShowOnMultiMeasureRests(V)then if finale.MNALIGN_LEFT~=T:GetMultiMeasureAlignment(V)then return false end elseif t.Measure==X.FirstMeasure then if not T:GetShowOnSystemStart()then return false end;if finale.MNALIGN_LEFT~=T:GetStartAlignment(V)then return false end else if not T:GetShowMultiples(V)then return false end;if finale.MNALIGN_LEFT~=T:GetMultipleAlignment(V)then return false end end;return z.is_default_measure_number_visible_on_cell(T,t,X,V)end;function z.update_layout(Z,_)Z=Z or 1;_=_ or false;local a0=finale.FCPage()if a0:Load(Z)then a0:UpdateLayout(_)end end;function z.get_current_part()local a1=finale.FCParts()a1:LoadAll()return a1:GetCurrent()end;function z.get_page_format_prefs()local a2=z.get_current_part()local a3=finale.FCPageFormatPrefs()local a4=false;if a2:IsScore()then a4=a3:LoadScore()else a4=a3:LoadParts()end;return a3,a4 end;local a5=function(a6)local a7=finenv.UI():IsOnWindows()local a8=function(a9,aa)if finenv.UI():IsOnWindows()then return a9 and os.getenv(a9)or""else return aa and os.getenv(aa)or""end end;local ab=a6 and a8("LOCALAPPDATA","HOME")or a8("COMMONPROGRAMFILES")if not a7 then ab=ab.."/Library/Application Support"end;ab=ab.."/SMuFL/Fonts/"return ab end;function z.get_smufl_font_list()local ac={}local ad=function(a6)local ab=a5(a6)local ae=function()if finenv.UI():IsOnWindows()then return io.popen('dir "'..ab..'" /b /ad')else return io.popen('ls "'..ab..'"')end end;local af=function(ag)local ah=finale.FCString()ah.LuaString=ag;return finenv.UI():IsFontAvailable(ah)end;for ag in ae():lines()do if not ag:find("%.")then ag=ag:gsub(" Bold","")ag=ag:gsub(" Italic","")local ah=finale.FCString()ah.LuaString=ag;if ac[ag]or af(ag)then ac[ag]=a6 and"user"or"system"end end end end;ad(true)ad(false)return ac end;function z.get_smufl_metadata_file(ai)if not ai then ai=finale.FCFontInfo()ai:LoadFontPrefs(finale.FONTPREF_MUSIC)end;local aj=function(ak,ai)local al=ak..ai.Name.."/"..ai.Name..".json"return io.open(al,"r")end;local am=aj(a5(true),ai)if am then return am end;return aj(a5(false),ai)end;function z.is_font_smufl_font(ai)if not ai then ai=finale.FCFontInfo()ai:LoadFontPrefs(finale.FONTPREF_MUSIC)end;if finenv.RawFinaleVersion>=z.finale_version(27,1)then if nil~=ai.IsSMuFLFont then return ai.IsSMuFLFont end end;local an=z.get_smufl_metadata_file(ai)if nil~=an then io.close(an)return true end;return false end;function z.simple_input(ao,ap)local aq=finale.FCString()aq.LuaString=""local ar=finale.FCString()local as=160;function format_ctrl(at,au,av,aw)at:SetHeight(au)at:SetWidth(av)ar.LuaString=aw;at:SetText(ar)end;title_width=string.len(ao)*6+54;if title_width>as then as=title_width end;text_width=string.len(ap)*6;if text_width>as then as=text_width end;ar.LuaString=ao;local ax=finale.FCCustomLuaWindow()ax:SetTitle(ar)local ay=ax:CreateStatic(0,0)format_ctrl(ay,16,as,ap)local az=ax:CreateEdit(0,20)format_ctrl(az,20,as,"")ax:CreateOkButton()ax:CreateCancelButton()function callback(at)end;ax:RegisterHandleCommand(callback)if ax:ExecuteModal(nil)==finale.EXECMODAL_OK then aq.LuaString=az:GetText(aq)return aq.LuaString end end;function z.is_finale_object(aA)return aA and type(aA)=="userdata"and aA.ClassName and aA.GetClassID and true or false end;function z.system_indent_set_to_prefs(X,a3)a3=a3 or z.get_page_format_prefs()local aB=finale.FCMeasure()local aC=X.FirstMeasure==1;if not aC and aB:Load(X.FirstMeasure)then if aB.ShowFullNames then aC=true end end;if aC and a3.UseFirstSystemMargins then X.LeftMargin=a3.FirstSystemLeft else X.LeftMargin=a3.SystemLeft end;return X:Save()end;function z.calc_script_name(aD)local aE=finale.FCString()if finenv.RunningLuaFilePath then aE.LuaString=finenv.RunningLuaFilePath()else aE:SetRunningLuaFilePath()end;local aF=finale.FCString()aE:SplitToPathAndFile(nil,aF)local D=aF.LuaString;if not aD then D=D:match("(.+)%..+")if not D or D==""then D=aF.LuaString end end;return D end;return z end)return a("__root")