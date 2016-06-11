---
title:  "Running Java inside Windows container on Windows server"
excerpt: "TBA"
categories:
  - JVM, Docker
tags:
  - Java, Docker
comments: true
share: true
---

### TL;DR
You can run .NET/Java/Node/Whatever inside Windows container hosted on Windows server.
All you need is to install Docker on Microsoft Server 2016 and create/pull a docker image from a registry.


### A new era?

There was(is?) a hype around .NET Core - open source, Linux support. People exulted at running .NET Core application inside Linux containers on Linux servers.
But can we do the completely opposite act. Can we run Java inside Windows container hosted on Windows server. Let's figure it out!
I stay away for reasons

### Windows and Docker

We need a system running Windows Server 2016 Technical Preview 5. Virtual machine works fine. BTW, It works on Windows 10 too.

TODO Compare docker repos

elevated PowerShell session.

```powershell
#  Install Container Feature
Install-WindowsFeature containers
Restart-Computer -Force # Yeah, it's still Windows

# Install Docker
New-Item -Type Directory -Path 'C:\Program Files\docker\'
Invoke-WebRequest https://aka.ms/tp5/b/dockerd -OutFile $env:ProgramFiles\docker\dockerd.exe
Invoke-WebRequest https://aka.ms/tp5/b/docker -OutFile $env:ProgramFiles\docker\docker.exe
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Program Files\Docker", [EnvironmentVariableTarget]::Machine)
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
dockerd --register-service
Start-Service Docker
```

```
Install-PackageProvider ContainerImage -Force
Install-ContainerImage -Name WindowsServerCore
Restart-Service docker
docker tag windowsservercore:10.0.14300.1000 windowsservercore:latest
docker images
```

If we check our pulled images we will see

```
PS C:\Windows\system32> docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
windowsservercore   10.0.14300.1000     dbfee88ee9fd        11 weeks ago        9.344 GB
windowsservercore   latest              dbfee88ee9fd        11 weeks ago        9.344 GB
```

Don't look at the image sizes. They are f* huge.

That's it. You're done with installation.



Let's launch the image we have:

```
docker pull microsoft/iis:windowsservercore
docker images
docker run -d -p 80:80 microsoft/iis:windowsservercore ping -t localhost
```


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

No Java unfortunately. How come???
Let's create it.

```
new-item c:\build\Dockerfile -Force

notepad c:\build\Dockerfile

FROM microsoft/iis:windowsservercore
RUN powershell (new-object System.Net.WebClient).Downloadfile('http://javadl.oracle.com/webapps/download/AutoDL?BundleId=210185', 'C:\jre-8u91-windows-x64.exe'); start-process -filepath C:\jre-8u91-windows-x64.exe -passthru -wait -argumentlist "/s,INSTALLDIR=c:\Java\jre1.8.0_91,/L,install64.log"; del C:\jre-8u91-windows-x64.exe

docker build -t java-windows c:\Build
```


```java
import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpServer;

public class Server {

    public static void main(String[] args) throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress(8000), 0);
        server.createContext("/ping", new MyHandler());
        server.setExecutor(null);
        server.start();
    }

    static class MyHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange t) throws IOException {
            String response = "pong";
            t.sendResponseHeaders(200, response.length());
            OutputStream os = t.getResponseBody();
            os.write(response.getBytes());
            os.close();
        }
    }
}
```





Linux images aren't supported. Yet?
