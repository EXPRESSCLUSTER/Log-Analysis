# ECX log analysis with Azure Log Analytics
   
To analyze ECX log file on Azure Log Analytics, the log file must meet the following criteria:

- The log must either have a single entry per line or use a timestamp matching one of the following formats at the start of each entry:
    ```
    YYYY-MM-DD HH:MM:SS
    M/D/YYYY HH:MM:SS AM/PM
    Mon DD, YYYY HH:MM:SS
    yyMMdd HH:mm:ss
    ddMMyy HH:mm:ss
    MMM d hh:mm:ss
    dd/MMM/yyyy:HH:mm:ss zzz
    yyyy-MM-ddTHH:mm:ssK
    ```
- The log file must not allow circular logging. This behavior is log rotation where the file is overwritten with new entries or the file is renamed and the same file name is reused for continued logging.
- The log file must use ASCII or UTF-8 encoding. Other formats such as UTF-16 aren't supported.
- For Linux, time zone conversion isn't supported for time stamps in the logs.
- As a best practice, the log file should include the date and time that it was created to prevent log rotation overwriting or renaming.

## Converting character-encoding, date & time format

ECX for Windows log file is encoded in SJIS, and has the date and time format as `YYYY/MM/DD HH:MM:SS.ZZZ`.
The following command can be used to convert it into UTF-8 and `YYYY-MM-D HH:MM:SS` format:

1. Install [Git for Windows](https://gitforwindows.org/).
2. Open `Git Bash`, then issue the following commands.
3. Change directory to the location where the ECX log files were extracted.
    ```sh
    cd /c/Users/USER-A/Downloads/SampleCluster/node-1/log
    ```
4. Convert the character encoding from SJIS to UTF-8.
    ```sh
    iconv -f SJIS -t UTF-8 userlog.00.log > userlog.00.utf8.log
    ```
5. Convert the date time format.
    ```sh
    sed -i -r 's/^(....)\/(..)\/(.. ..:..:..)\./\1-\2-\3 /' userlog.00.utf8.log
    ```
## Custom Logs

First you will need a Log Analytics workspace in Azure. Search for *Log Analytics workspaces* from the Azure home page and create a new workspace.   

### Link to log files on your PC

Install the Log Analytics agent on your PC.

1. Open the Log Analytics workspace and go to *Agents Management*.
2. Select the Windows servers tabl or the Linux servers tab, depending on the OS where your log files exist.
3. Expand *Log Analytics agent instructions*.
4. Download the appropriate agent for your OS.
5. Copy the *Workspace ID* and the *Primary key* (which will be used later to link your PC to the Azure Log Analytics workspace).
6. Install the Log Analytics agent on your PC and input the *Workspace ID* and the *Primary key* in the appropriate fields.

Add custom logs.

1. Open the Log Analytics workspace you created and click on *Custom logs* under *Settings*.
2. Click on *Add custom log* under the *Custom tables* tab.
3. Select one of the log files in the log files folder on your PC as a sample log. Click Next.
4. The contents of the log file should display in the Preview windows. Choose *New line* as the delimeter. Click Next.
5. Choose the appropriate OS as the *Type* and then enter the path to the log files.    
    e.g. C:\\temp\\logfiles\\\*.log
    Click Next.
7. Enter a name for the log file. Note that it will automatically be appended with '\_CL'. Click Next.
8. Click *Create*.
