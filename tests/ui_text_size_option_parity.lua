-- v0.4.30: UI text size control is categorized under UI and has safe bounds.
local schema=assert(loadfile("options.lua"))()
local found
for _,row in ipairs(schema or {}) do
  if row.key=="uiTextSize" then found=row break end
end
assert(found,"uiTextSize option exists")
assert(found.type=="number","uiTextSize uses numeric slider semantics")
assert(found.default==100,"uiTextSize defaults to 100 percent")
assert(found.min==75 and found.max==160,"uiTextSize has readable safe bounds")
assert(found.step==5,"uiTextSize changes in 5 percent steps")
local src=assert(io.open("lib/CategorizedModSettings.lua","rb")):read("*a")
assert(src:find("uiTextSize=true",1,true),"UI category owns uiTextSize")
assert(src:find("local function uiTextScale",1,true),"modern UI has live text scale helper")
assert(src:find('row.id == "uiTextSize"',1,true),"modern row displays uiTextSize specially")
print("ui_text_size_option_parity: OK")
