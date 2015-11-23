---
layout: post
title: "HOWTO: Check JIT Inlining"
date: 2015-11-21T15:33:28+02:00
modified: 2015-11-23T12:06:00+02:00
categories: [.NET, CLR, JIT]
excerpt: A short HOWTO check whether methods were inlined by JIT or not, and why not.
tags: [.NET, CLR, JIT, Optimizations]
comments: true
share: true
---

### TL;DR

```
logman start InliningEvents ^
    -p {e13c0d23-ccbc-4e12-931b-d9cc2eee27e4} ^
    0x00001000 0x5 -ets -ct perf

//start your app and execute the code you want to check

logman stop InliningEvents -ets
tracerpt InliningEvents.etl
//Observe or script dumpfile.xml
```

### Details

From time to time, I work on micro-optimizations of hot paths and need to check whether the methods were inlined by JIT or not, and why not.
I do that occasionally and always google for tools to use, parameters to pass and scripts to analyze. So that I decided to create a small manual for myself, but, probably, you will find it useful too.

#### Step 1. Start capturing.
JIT leverages Event Tracing for Windows (ETW) and logs [some of its events][msdn-jitevents] there, including Inlining events. I use [Logman][technet-logman] to capture ETW events, which is a CLI to manage ETW sessions and performance logs. The following command starts logging events:

```
logman start InliningEvents ^
    -p {e13c0d23-ccbc-4e12-931b-d9cc2eee27e4} ^
    0x00001000 0x5 -ets -ct perf
```

* `InliningEvents` - name of your session.  
* `-p {e13c0d23-ccbc-4e12-931b-d9cc2eee27e4}` - identifies [the provider GUID][msdn-providers]. CLR provider in our case.  
* `0x00001000` specifies [the categories of events][msdn-etwkeywords] that will be raised. "JITTracingKeyword" in our case.  
* `0x5` sets [the level of logging][msdn-eventslevel]. Verbose in this case.  
* `-ets` - instructs `Logman` to send commands to event tracing sessions.  
* `-ct perf` - specifies that the `QueryPerformanceCounter` function will be used to log the time stamp for each event.  

#### Step 2. Execute your code.
Launch your application and execute the code you want to check to let JIT work.

#### Step 3. Stop capturing.
The following command stops capturing events and creates a binary trace file named _InliningEvents.etl_.

```
logman stop InliningEvents -ets
```

#### Step 4. Parse results.
I use [Tracerpt][technet-tracerpt] to parse the binary trace file and generate human readable files.

The following command creates two files: _dumpfile.xml_ and _summary.txt_. The _dumpfile.xml_ file lists all the events, and _summary.txt_ provides a summary of the events.

```
tracerpt InliningEvents.etl
```

#### Step 5. Script the output.

The parsed output file is in XML format that pretty easy to read, but it's more easier and fun to script it. Something like the following code works for me. You can run it via [scriptcs][scriptcs] or a console app.  

```csharp
using System;
using System.Linq;
using System.Xml.Linq;

const string InliningFailedEventId = "186";

var root = XElement.Load("dumpfile.xml");
XNamespace ns = "http://schemas.microsoft.com/win/2004/08/events/event";
XNamespace nsInner = "myNs";

foreach (var e in root.Elements()
    .Where(e => e.Elements(ns + "System")
        .Any(s => s.Elements(ns + "EventID")
            .Any(i => i.Value == InliningFailedEventId))))
{
    var failData = e.Element(ns + "UserData").Element(nsInner + "MethodJitInliningFailed");

    var inliner = failData.Element(nsInner + "InlinerNamespace").Value + failData.Element(nsInner + "InlinerName").Value;
    var inlinee = failData.Element(nsInner + "InlineeNamespace").Value + failData.Element(nsInner + "InlineeName").Value;
    var failReason = failData.Element(nsInner + "FailReason").Value;

    Console.WriteLine("Inliner: " + inliner);
    Console.WriteLine("Inlinee: " + inlinee);
    Console.WriteLine("Fail reason: " + failReason);
    Console.WriteLine();
}
```

Do you want to have more sophisticated analysis? Take a look at [Microsoft TraceEvent Library][nuget-traceevent].  
You can find [the samples and docs on github][github-traceevent].


#### Entertainment

"A story about JIT-x86 inlining and starg" [on Andrey Akinshin's blog][story]



  [msdn-jitevents]: https://msdn.microsoft.com/library/ff356158(v=vs.100).aspx
  [technet-logman]: https://technet.microsoft.com/en-us/library/cc753820.aspx
  [msdn-etwkeywords]: https://msdn.microsoft.com/en-us/library/ff357720(v=vs.100).aspx
  [msdn-eventslevel]: https://msdn.microsoft.com/en-us/library/ff357720(v=vs.100).aspx#Anchor_1
  [technet-tracerpt]: https://technet.microsoft.com/en-us/library/cc732700.aspx
  [msdn-providers]: https://msdn.microsoft.com/en-us/library/ff357718(v=vs.100).aspx
  [scriptcs]: http://scriptcs.net/
  [story]: http://aakinshin.net/en/blog/dotnet/inlining-and-starg/
  [nuget-traceevent]: https://www.nuget.org/packages/Microsoft.Diagnostics.Tracing.TraceEvent/
  [github-traceevent]: https://github.com/Microsoft/dotnetsamples/blob/master/Microsoft.Diagnostics.Tracing/TraceEvent/docs/TraceEvent.md
