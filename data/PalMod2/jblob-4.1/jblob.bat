@ECHO OFF

:: Installation directory
SET JBLOB_HOME=%~dp0

:: Java home directory, set to location of installed Java runtime environment
:: or can be commented out if JAVA_HOME environment variable is set globally.
SET JAVA_HOME="C:\Program Files\Eclipse Adoptium\jdk-11.0.21.9-hotspot"

%JAVA_HOME%\bin\java -mx100m -classpath %JBLOB_HOME%\lib\jblob.jar de.dkrz.cera.application.JblobClient %*
