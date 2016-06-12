---
title:  "Running Java inside a Windows container on a Windows server"
excerpt: "You can run Java inside a Windows container which is hosted on a Windows server. And here's how..."
categories: [Docker]
tags: [Just For Fun, Java, Docker, Windows]
layout: single
comments: true
share: true
---

### TL;DR

You can run .NET/Java/Node.js/Whatever inside Windows containers hosted on Windows servers. All you need is: Windows Server 2016 (Windows 10), install Docker, install the Windows base image, create/pull a docker image from a registry.


### A new era?

There was(is?) a hype around .NET Core: C# language, .NET Framework and Runtime were open-sourced. They got Linux support. People exulted at running .NET Core applications inside Linux containers on Linux servers. Which is very cool, I'm sure. Let's put .NET Core and tools a bit aside otherwise I end
But can we do the completely opposite act? Can we run Java inside Windows container hosted on Windows server? Let's figure it out!
I stay away for reasons

### Windows and Docker

We need a system running Windows Server 2016 Technical Preview 5. Virtual machine works fine. (BTW, It works on Windows 10 too.)

TODO Compare docker repos

elevated PowerShell session.


#### 1. Install Container Feature
```powershell
Install-WindowsFeature containers
Restart-Computer -Force # Yeah, it's still Windows ¯\_(ツ)_/¯
```

#### 2. Install Docker
```powershell
# Create a directory
New-Item -Type Directory -Path 'C:\Program Files\Docker\'
# Download the Docker daemon
Invoke-WebRequest https://aka.ms/tp5/b/dockerd -OutFile $env:ProgramFiles\Docker\dockerd.exe
# Download the Docker client
Invoke-WebRequest https://aka.ms/tp5/b/docker -OutFile $env:ProgramFiles\Docker\docker.exe
# Add the Docker directory to the system path
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Program Files\Docker", [EnvironmentVariableTarget]::Machine)
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
# Install as a Windows service
dockerd --register-service
Start-Service Docker
```

#### 3. Install Base Container Image

the Windows Server Core base image

```powershell
Install-PackageProvider ContainerImage -Force
Install-ContainerImage -Name WindowsServerCore
Restart-Service docker
docker tag windowsservercore:10.0.14300.1000 windowsservercore:latest
```

If we check installed images we will see the following picture. (Don't look at the image sizes otherwise you'll be scared.)

```
PS C:\Windows\system32> docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
windowsservercore   10.0.14300.1000     dbfee88ee9fd        11 weeks ago        9.344 GB
windowsservercore   latest              dbfee88ee9fd        11 weeks ago        9.344 GB
```

If the command executed successfully and we see the images then we are good. That's all we need to start with container images.


### Windows container images

Let's have a look at the images that Microsoft provides:

```
PS C:\Windows\system32> docker search microsoft
NAME                                         DESCRIPTION                                     STARS     OFFICIAL   AUTOMATED
microsoft/sample-django:windowsservercore    Django installed in a Windows Server Core ...   1                    [OK]
microsoft/dotnet35:windowsservercore         .NET 3.5 Runtime installed in a Windows Se...   1         [OK]       [OK]
microsoft/sample-golang:windowsservercore    Go Programming Language installed in a Win...   1                    [OK]
microsoft/sample-httpd:windowsservercore     Apache httpd installed in a Windows Server...   1                    [OK]
microsoft/iis:windowsservercore              Internet Information Services (IIS) instal...   1         [OK]       [OK]
microsoft/sample-mongodb:windowsservercore   MongoDB installed in a Windows Server Core...   1                    [OK]
microsoft/sample-mysql:windowsservercore     MySQL installed in a Windows Server Core b...   1                    [OK]
microsoft/sample-nginx:windowsservercore     Nginx installed in a Windows Server Core b...   1                    [OK]
microsoft/sample-python:windowsservercore    Python installed in a Windows Server Core ...   1                    [OK]
microsoft/sample-rails:windowsservercore     Ruby on Rails installed in a Windows Serve...   1                    [OK]
microsoft/sample-redis:windowsservercore     Redis installed in a Windows Server Core b...   1                    [OK]
microsoft/sample-ruby:windowsservercore      Ruby installed in a Windows Server Core ba...   1                    [OK]
microsoft/sample-sqlite:windowsservercore    SQLite installed in a Windows Server Core ...   1                    [OK]
```

It's long enough for the start: .NET, IIS, Go, Python, Ruby, MySQL, ... Wait! Where's Java? How come??? Okay, Let's create it by ourselves.

Create a Dockerfile, `c:\java-windows-docker\Dockerfile`, and put the following lines inside:

```
FROM windowsservercore
RUN powershell (new-object System.Net.WebClient).Downloadfile('http://javadl.oracle.com/webapps/download/AutoDL?BundleId=210185', 'C:\jre-8u91-windows-x64.exe'); start-process -filepath C:\jre-8u91-windows-x64.exe -passthru -wait -argumentlist "/s,INSTALLDIR=c:\Java\jre1.8.0_91,/L,install64.log"; del C:\jre-8u91-windows-x64.exe
CMD [ "c:\\Java\\jre1.8.0_91\\bin\\java.exe", "-version"]
```

It downloads the Java 8 Update 91 Windows installer and silently installs it to `c:\Java\jre1.8.0_91`. After start, the container prints out the java version.  
Let's build the image:

```
docker build -t java-windows-docker c:\java-windows-docker
```

And if we run it...

```
PS C:\Windows\system32> docker run java-windows-docker
java version "1.8.0_91"
Java(TM) SE Runtime Environment (build 1.8.0_91-b15)
Java HotSpot(TM) 64-Bit Server VM (build 25.91-b15, mixed mode)
```

We get Java running. Wow! Amazing!! We have Java running inside a Windows container that is hosted on a Windows server. Frankly, I won't believe this a couple of years ago. But now things get real!

What about Linux containers on Windows server? Unfortunately they aren't supported. You will get an error if you try to pull/run one. But, I believe, it's just a matter of time and we could run .NET Core inside a Linux container on a Windows server soon. Such a crazy time!

### References

MSDN: [Windows Containers Documentation](https://msdn.microsoft.com/virtualization/windowscontainers/containers_welcome)

MSDN: [Quick Start: Windows Containers on Windows Server](https://msdn.microsoft.com/en-us/virtualization/windowscontainers/quick_start/quick_start_windows_server)

Channel 9: [Containers 101 with Microsoft and Docker](https://channel9.msdn.com/Blogs/containers/Containers-101-with-Microsoft-and-Docker)

MSDN: [Windows Containers on Windows 10](https://msdn.microsoft.com/en-us/virtualization/windowscontainers/quick_start/quick_start_windows_10)

GitHub: [.NET Core Docker Images](https://github.com/dotnet/dotnet-docker)
