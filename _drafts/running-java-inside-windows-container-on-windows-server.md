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

You can run .NET/Java/Node.js/Whatever inside native Windows containers hosted on Windows servers. All you need is: Windows Server 2016 (or Windows 10), install Docker, install the Windows base image, create/run a docker image from a registry.


### A new era?

There was(is?) a hype around Microsoft and .NET: C# language, .NET Framework and CLR Runtime have been open-sourced. They got Linux support. People exulted at running .NET Core applications inside Linux containers on Linux servers. Which is very cool, I'm sure. But let's put .NET Core and tools aside otherwise I'll end up crying (early adopters would understand).

There is an idea stuck in my head since: can we do the completely opposite act? Can we run Java inside a Windows container hosted on a Windows server? I don't mean tools like [Boot2Docker](http://boot2docker.io/), [Kitematic](https://kitematic.com/) or new [Docker Toolbox](https://www.docker.com/products/docker-toolbox). They are all essentially a Linux VM. What I mean is native Docker experience on Windows where containers run natively without any virtualization layer.

Let's figure it out!

### Windows and Docker

We need a system running [Windows Server 2016 which is Technical Preview 5][microsoft-windows-server] at the moment. _BTW, It works on Windows 10 too, see the references below._ Virtual machine works fine. In next steps we are going to enable the Container feature, install Docker and the base image. We need elevated PowerShell session on the system for that. Let's go!


#### 1. Install Container Feature
```powershell
Install-WindowsFeature containers
Restart-Computer -Force # Yeah, it's still Windows ¯\_(ツ)_/¯
```

#### 2. Install Docker

Microsoft has [its own fork of Docker](https://github.com/microsoft/docker). They ship their own versions of the docker daemon and the docker client. Let's get them:

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

Next we need to install the Windows Server Core base image which is provided by Microsoft and includes the core OS components. It is used as a base image by other Windows-based images.

```powershell
Install-PackageProvider ContainerImage -Force
Install-ContainerImage -Name WindowsServerCore -Version 10.0.14300.1000
Restart-Service docker
docker tag windowsservercore:10.0.14300.1000 windowsservercore:latest
```

If we check installed images we will see the following picture. (Please, don't look at the images' sizes otherwise you'll be scared.)

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

It's long enough for the start: .NET, IIS, Go, Python, Ruby, MySQL, ... Wait! Where's Java? How come??? Okaaay, Let's create it by ourselves.

#### 4. Create an image with Java

Create a Dockerfile, `c:\java-windows-docker\Dockerfile`, and put the following lines inside:

```
FROM windowsservercore

RUN powershell (new-object System.Net.WebClient).Downloadfile('http://javadl.oracle.com/webapps/download/AutoDL?BundleId=210185', 'C:\jre-8u91-windows-x64.exe')
RUN powershell start-process -filepath C:\jre-8u91-windows-x64.exe -passthru -wait -argumentlist "/s,INSTALLDIR=c:\Java\jre1.8.0_91,/L,install64.log"
RUN del C:\jre-8u91-windows-x64.exe

CMD [ "c:\\Java\\jre1.8.0_91\\bin\\java.exe", "-version"]
```

It downloads the Java 8 Update 91 Windows installer and silently installs it to `c:\Java\jre1.8.0_91`. After start, the container launches Java and prints out its version.  
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

We have Java running. Wow! Amazing!! We have Java running inside a Windows docker container which is hosted on a Windows server. Frankly, I wouldn't believe this a couple of years ago. But things got real now!

What about Linux containers on Windows server? Unfortunately they aren't supported. You will get an error if you try to pull/run one. But, it won't surprise me if we could run .NET Core inside a Linux container on a Windows server sometime. Such a crazy time to code!

### References

MSDN: [Windows Containers Documentation](https://msdn.microsoft.com/virtualization/windowscontainers/containers_welcome)

MSDN: [Quick Start: Windows Containers on Windows Server](https://msdn.microsoft.com/en-us/virtualization/windowscontainers/quick_start/quick_start_windows_server)

Channel 9: [Containers 101 with Microsoft and Docker](https://channel9.msdn.com/Blogs/containers/Containers-101-with-Microsoft-and-Docker)

MSDN: [Windows Containers on Windows 10](https://msdn.microsoft.com/en-us/virtualization/windowscontainers/quick_start/quick_start_windows_10)

GitHub: [.NET Core Docker Images](https://github.com/dotnet/dotnet-docker)

GitHub: [Windows Containers samples](https://github.com/Microsoft/Virtualization-Documentation/tree/0adba7327db5b56bbb3c9cf49bdb73d579a5d5d8/windows-container-samples/windowsservercore)

  [microsoft-windows-server]: https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-technical-preview
