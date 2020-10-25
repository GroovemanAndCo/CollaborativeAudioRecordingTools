-- Collab_Open
-- Cpl Crapper
-- Version 1.7beta 24/10/2020
-- Added timestamp to lock file and create .Project.opn when trying a locked project

-- This script is for opening a Reaper project for Collaboration
-- It checks to see if there is a lock file in the selected projects directory
-- If the lock file exists it prevents the opening of the project
-- Otherwise it will open the project and create a lock file
-- Hence preventing other users from opening the project
--
Version = "1.7beta"

--
-- FUNCTIONS
--
function clear_lock_track()
 -- find any PROJECT LOCK tracks and remove them
    index = reaper.GetNumTracks()
    for i = 1, index - 1  do
        -- get each track
        track = reaper.GetTrack(0, i) -- Get selected track i
        
        -- Get title Property Value
        retval,title = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
        -- check to see it this is the LOCK track and remove
        if title == "PROJECT LOCKED BY YOU"
        then
          reaper.DeleteTrack(track)
        end
    
    end
end

function get_project(filename)
    
    -- this project will be opened and locked
    -- open project
    reaper.Main_openProject(filename) -- we really need a test on this
    clear_lock_track()-- In case any were left over from previous aborts
    
    -- setup a new track as a visual indicator of locking as last track (index)
    index = reaper.GetNumTracks()
    reaper.InsertTrackAtIndex(index, false)
    
    -- set track color red
    track = reaper.GetTrack(0,index)
    color = reaper.ColorToNative(255,0,0)
    reaper.SetTrackColor(track,color)
    
    -- set track title
    reaper.GetSetMediaTrackInfo_String(track,"P_NAME","PROJECT LOCKED BY YOU",true)
    
    -- set track icon
    reaper.GetSetMediaTrackInfo_String(track,"P_ICON","group.png",true)
    
    -- save the project name to Extrenal State indicate we have it locked
    projectname = reaper.GetProjectName(0,"")
    reaper.SetExtState("","Locked",filename,true)
    
    -- create the lock file
    io.output(lockfile)
    io.write(mylocktext)
    io.close()
    
    -- this does not work
    if string.match(reaper.GetOS(), "Win")
    then
      -- make this a hidden file for DOS
      execstring = "%PATH%\attrib +h " .. lockfile
      os.execute(execstring)
    end
end

function show_dialog(lastline,message,buttons)
  title = "Reaper Cloud Collaboration ("..Version..")"
  output = message .. "\n" .. lastline
  exit_code = reaper.ShowMessageBox(output,title,buttons)
  return(exit_code)
end

function clear_project ()

-- Force Open an empty template to quit and clear the project
    template = reaper.GetResourcePath()
    template = "template:noprompt:" .. template .. sep .. "ProjectTemplates" .. sep .. "Empty.rpp"
    reaper.Main_openProject(template)

-- remove the lock and ExtState value
    reaper.SetExtState("","Locked","",true)
    lock = ".Project.lck"
    lockfile = projectpath..sep..lock
    remval = os.remove(lockfile)
 
end

------------------------------------------------------------------------
-- MAIN
------------------------------------------------------------------------
-- set OS dependent variables
sep = string.match(reaper.GetOS(), "Win") and "\\" or "/"

-- Do we have previously saved values for Drive and Email
-- if we dont then we need to ask for them

-- get the external state values for Drive and Email
my_drive = reaper.GetExtState("","Drive")
my_email = reaper.GetExtState("","Email")
my_name = reaper.GetExtState("","Name")

if my_drive == "" or my_email == "" or my_name == ""
then
  -- work out path name to run Collab_Setup
  collab_setup = debug.getinfo(1).source:sub(2)
  collab_setup = collab_setup:gsub("Collab_Open","Collab_Setup")
  
  -- run Collab_Setup
  dofile(collab_setup)
  
  my_drive = reaper.GetExtState("","Drive")
  my_email = reaper.GetExtState("","Email")
  my_name = reaper.GetExtState("","Name")
end

-- set the text to save in the lock file
-- save a time stamp in the lock file
my_time = os.time()
  --    date = os.date("%c",time)
  --  reaper.ShowMessageBox(date,"",0)
mylocktext = my_time ..":" .. my_name .. " (" .. my_email .. ")"
mylockname = my_name .. " (" .. my_email .. ")"

-- are they trying to open another project when they have a collab project open
-- check for value in ExtState variable 
currentproject = reaper.GetExtState("","Locked")

-- set savval to 1 (Collab_Save may set it to 2 if Cancel is selected)
if currentproject ~= ""
then

  -- work out path name to run Collab_Save
    collab_save = debug.getinfo(1).source:sub(2)
    collab_save = collab_save:gsub("Collab_Open","Collab_Save")
    
    -- run Collab_Save
    savval = dofile(collab_save)
end


if savval ~= 2 -- If it is 2 a cancel was returned by Collab_Save and we quit
then
    -- here we would present a file browser for selecting the project
    retval,projectfile = reaper.GetUserFileNameForRead(my_drive, "Choose a Project", "*.rpp;*.rpp-bak")

    if retval -- this means a project file has been chosen
    then

          -- get project path name by matching all up to last slash of the filename
          projectpath = projectfile:match("(.*"..sep..")")
  
          -- define the lock file name
          lock = ".Project.lck"
          lockfile = projectpath .. lock

          if reaper.file_exists(lockfile)
          then
              --
              -- This project is locked by you or another another user
              -- read the text from the lockfile
              io.input(lockfile)
              locktext = io.read("*line")
              io.close()
              -- strip out the epoch date from locktext
              locktime = "" -- preset to null value
              locktime,lockname = locktext:match("([^:]+):([^:]+)")
              
              
              -- is this the older form of locktext ie Name Email
              if locktime == nil
              then
                lockname = locktext
                lockdate = ""
              else
              
                lockdate = os.date("%c",locktime)
              end
              
              -- is this project locked by you
              if mylockname == lockname
              then
                  openagain = show_dialog(projectfile,"Opening Locked Project.\nDo you want to Unlock and Close it?",4)
                  if openagain == 6 -- (Yes)
                  then
                      clear_project()
                  else -- (No)
                      projectfile = "noprompt:" .. projectfile
                      get_project(projectfile)
                  end -- if openagain == 6
              else    
              
                  -- this project is locked by another user
 
                  -- create the lock file
                      open = ".Project.opn"
                      openfile = projectpath..sep..open
                      io.output(openfile)
                      io.write(mylockname)
                      io.close()
                      show_dialog(lockdate,projectfile .. "\n* LOCKED BY *".."\n" .. lockname,0)
              end -- if mylocktext == locktext
          else
            get_project(projectfile)
          end
    end -- if retval
end
