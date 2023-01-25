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
