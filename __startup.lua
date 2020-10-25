-- __startup.lua
-- Cpl Crapper
-- Version 1.7beta 24/10/2020
--
-- Reaper startup script
-- Check to see if we have an open Collab project
-- If we do have one then if its is already preloaded
-- we load it again to ensure that the RED warning track is included
-- In this case we remind the user that he still has it locked
--
-- If we are starting with a clean project then we remind him and ask if he wants to open it.
--
-- It also creates a long running background process using reaper.defer to poll for a file
-- that gets created when someone else tries to open an already opened project
-- if the file (.Project.opn) has contents then they are displayed in a console window
Version = "1.7beta"

function show_dialog(lastline,message,buttons)

    title = "Reaper Cloud Collaboration ("..Version..")"
    output = message .. "\n" .. lastline
    exit_code = reaper.ShowMessageBox(output,title,buttons)
  return(exit_code)
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

function get_project(filename)
    
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
    
    -- save the project name to External State indicate we have it locked
    projectname = reaper.GetProjectName(0,"")
    reaper.SetExtState("","Locked",filename,true)
   -- no need to create lock file it already exists
   -- but it might not so create it again
   
end

function other_open()
  
  -- this function will run in the background using reaper.defer
  -- to check if someone else attempts to open the currently opened project
  -- a message is displayed to us if there is a request
  currentproject = reaper.GetExtState("","Locked")
  
  if currentproject ~= "" -- we have a locked project
  then
    -- we are using a locked project
    -- now look for a .Project.opn in the Path
      checkpath = reaper.GetProjectPath(0,"")
      checkopn = checkpath .. sep .. ".Project.opn"
      
      if reaper.file_exists(checkopn)
      then
        -- someone has flagged a request to open this project
        -- get the contents of the file
    
        fd_r = io.open(checkopn,"r")
        usertext = fd_r:read()
        io.close(fd_r)
        
        -- is the file empty (workaround for os.remove on windows not removing file created by someone else)
        
        if usertext ~= nil
        then
          
          -- mylocktext is a global
          if mylocktext ~= usertext -- this is for someone elses open request
          then
          
            -- only display when it is someone elses request
            -- get the time and date to display
            date = os.date("%c",(os.time()))
            reaper.ShowConsoleMsg(date.."\nAttempt to Open this Project by:\n"..usertext.."\n\n")
           
          end -- someone elses open request
          
          -- now clear the opn request file whether mine or theirs
          -- remove the opn file so we don't get an infinite number of messages
          -- just overwrite the file with nothing os.remove has issues
                     
          fd_w = io.open(checkopn,"w")
          fd_w:write("")
          io.close(fd_w)
        end -- usertext contains data
      end -- checkopn exists
  end -- we have a project
  
  -- Now run this function again as a defer so it loops forever
  reaper.defer(other_open)
  
end -- end function
    

------------------------------------------
-- MAIN
------------------------------------------

-- this is to warn the user if they bombed out with a reaper quit
-- without saving the project back
sep = string.match(reaper.GetOS(), "Win") and "\\" or "/"

-- get Ext State for Name and Email for potential lock file contents
my_email = reaper.GetExtState("","Email")
my_name = reaper.GetExtState("","Name")

-- set the text to save in the lock file
mylocktext = my_name .. " (" .. my_email .. ")"

-- see if we have a value in Ext State Locked ie: is there a previously locked project
my_project = reaper.GetExtState("","Locked")
if my_project ~= ""

then
    -- strip noprompt: from my_project
    --my_project = string.gsub(my_project,"noprompt:","")
    
    --noprompt,my_project = my_project:match("(noprompt):(.*)")
    projectdir = my_project:match("(.*"..sep..")")
    --reaper.ShowConsoleMsg("Locked "..my_project)
    -- so we have a project name in the ExtState "Locked" but is there a lock file that matches me
    -- if no lock file then it ain't locked
    -- work out lock file name
    lockfile = projectdir .. ".Project.lck"
    if reaper.file_exists(lockfile)
    then
        --reaper.ShowConsoleMsg("\nFound "..lockfile)    
        -- now check it is our lock file
        io.input(lockfile)
        locktext = io.read("*line")
        io.close()
        --reaper.ShowConsoleMsg("TEXT "..locktext)
        -- strip out the epoch date from locktext
        --locktime = "" -- preset to null value
        locktime,lockname = locktext:match("([^:]+):([^:]+)")
                      
        -- is this the older form of locktext ie Name Email
        if locktime == nil
        then
            lockname = locktext
        end
        --reaper.ShowConsoleMsg("Match? "..mylocktext.. " with " .. lockname)
        -- see if it is our lock file ie text matches me  
        if mylocktext == lockname
        then
            
            -- then we have to load it and tell me
            show_dialog(my_project,"Opening Project Previously Locked by You\n",0)
                
            -- re-opening a locked project already opened ensures the red reminder track is loaded
            get_project(my_project)
        else
        
            -- this lock file is locked by someone else so clear extState
            reaper.SetExtState("","Locked","",true)
        end -- mylocktext == locktext    
    else
        
        -- lock file does not exist clear the extState
        reaper.SetExtState("","Locked","",true)
    end -- reaper.file_exits(lockfile)
    
end -- my_project ~= ""


-- Now run the defer function (in background because it calls itself again)
other_open()


