-- Collab_Save
-- Cpl Crapper
-- Version 1.7beta 24/10/2020

Version = "1.7beta"
--
-- FUNCTIONS
--
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
    
    
    --if not remval
    --then
    --  reaper.ShowMessageBox(lockfile,"Error Can't Remove Lockfile",0)
    --end
end

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

function show_dialog(lastline,message,buttons)

  -- function to make message neater in Windows
--  if string.match(reaper.GetOS(), "Win")
  --then
    title = "Reaper Cloud Collaboration ("..Version..")"
    output = message .. "\n" .. lastline
    exit_code = reaper.ShowMessageBox(output,title,buttons)
  --else
    --exit_code = reaper.ShowMessageBox(lastline,message,buttons)
  --end
  return(exit_code)
end

---------------------------------------------------------------------------
-- MAIN
---------------------------------------------------------------------------
-- set OS dependent variables
sep = string.match(reaper.GetOS(), "Win") and "\\" or "/"

-- Do we have previously saved values for Drive and Email
-- if we dont then we need to ask for them

-- get projectpath
-- Are we saving a Collaboration project ie: currently locked project
locked = reaper.GetExtState("","Locked")
if locked == ""
then
  --
  -- this is a new project to be saved
  retval = show_dialog(locked,"Do you want to Save a New Project?",4)
  if retval == 6
  then
    -- save the project back to the cloud
        reaper.Main_SaveProject(0,true)
  end
  
else

  -- this is a current project that we are updating to the cloud
  projectpath = reaper.GetProjectPath("")
  projectname = reaper.GetProjectName(0,"")
  --reaper.ShowMessageBox(projectname,"Name",0)
  if projectname ~= ""
  then
      savval = show_dialog(projectname,"Do you want to Save the Locked Project Before Closing?",3)
      -- 1, OK 2, CANCEL 3, ABORT 4, RETRY 5, IGNORE 6, YES 7, NO
  
      if savval == 6 -- Save and Close
      then
   
        clear_lock_track()   
        -- save the project back to the cloud
        reaper.Main_SaveProject(0,false)
   
        clear_project() 
      end 
  
      if savval == 7 -- Quit no Close (lock track will still be there we will remove it on next collab open)
      then

        clear_project() 
      end
  
      -- return the result of the Save? messagebox in case this was called by Collab_Open
      if savval == 2
      then
        return savval
      end
  end
end





