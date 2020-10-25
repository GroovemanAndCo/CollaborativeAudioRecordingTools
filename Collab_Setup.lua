-- Collab_Setup.lua
-- Cpl Crapper
-- Version 1.7beta 24/10/2020
Version = "1.7beta"
-- set OS dependent variables
sep = string.match(reaper.GetOS(), "Win") and "\\" or "/"

-- This uses External State Data saved after Reaper quits (ie: persistant)
-- Get previously saved values (if any) for Drive and Email and Name
extstate_drive_key = "Drive" 
extstate_email_key = "Email"
extstate_name_key = "Name"
my_drive = reaper.GetExtState("",extstate_drive_key)
my_email = reaper.GetExtState("",extstate_email_key)
my_name = reaper.GetExtState("",extstate_name_key)
my_inputs = my_drive .. "," .. my_name .. "," .. my_email

-- Show Input dialog displaying current values (if any)
-- User can change the values which will update the External State Data

ret_val,new_inputs = reaper.GetUserInputs("Reaper Cloud Collaboration ("..Version..")",3,"Cloud Drive Path:,Your Name:,Your Email Address:,extrawidth=200",my_inputs)

-- split the returned csv string
new_drive, new_name, new_email = new_inputs:match("([^,]+),([^,]+),([^,]+)")

-- add seperator to drive name if not one there already

-- new_drive = new_drive .. sep

-- if user selects OK run this to update the External State Data
if ret_val
then
  -- set google_drive value
  reaper.SetExtState("",extstate_drive_key,new_drive,true)

  -- set my_email value
  reaper.SetExtState("",extstate_email_key,new_email,true)
  
  -- set my_name value
  reaper.SetExtState("",extstate_name_key,new_name,true)
  
 -- Check to see if the Google Drive is accessible
 if reaper.EnumerateSubdirectories(new_drive,0)
  then
   -- Do nothing
  else
    reaper.ShowMessageBox(new_drive,"Warning: Can't Open",0)
  end 
end


