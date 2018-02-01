core Flight System (cFS) Memory Dwell Application (MD) 
Open Source Release Readme

MD Release 2.3.1 

Date: 
July 14, 2017

Introduction:
  The Memory Dwell application (MD) is a core Flight System (cFS) application 
  that is a plug in to the Core Flight Executive (cFE) component of the cFS.  
  
  The cFS is a platform and project independent reusable software framework and
  set of reusable applications developed by NASA Goddard Space Flight Center.  
  This framework is used as the basis for the flight software for satellite data 
  systems and instruments, but can be used on other embedded systems.  More 
  information on the cFS can be found at http://cfs.gsfc.nasa.gov
  
  The MD application monitors memory addresses accessed by the CPU. This task 
  is used for both debugging and monitoring unanticipated telemetry that had
  not been previously defined in the system prior to deployment.   

  The MD application is written in C and depends on the cFS Operating System 
  Abstraction Layer (OSAL) and cFE components.  To build and run the MD
  application, follow the cFS Deployment Guide instructions contained in 
  cFE-6.5.0a-OSS-release/docs.  There is additional MD application specific 
  configuration information contained in the application user's guide
  available in cfs-md-2.3.1-OSS-release/docs/users_guide
  
  There are also "Quick start" instructions provided in 
  cFE-6.5.0a-OSS-release/cfe-OSS-readme.txt   
  
  The OSAL is available at http://sourceforge.net/projects/osal/ and 
  github.com/nasa/
  
  The cFE is available at http://sourceforge.net/projects/coreflightexec

  This software is licensed under the NASA Open Source Agreement. 
  http://ti.arc.nasa.gov/opensource/nosa
 
 
Software Included:
  Memory Dwell application (MD) 2.3.1
  
 
Software Required:

 Operating System Abstraction Layer 4.2.0 or higher can be 
 obtained at http://sourceforge.net/projects/osal or 
 github.com/nasa/osal
 
 core Flight Executive 6.5.0 or higher can be obtained at
 http://sorceforge.net/projects/coreflightexec

  
Runtime Targets Supported:
   The "out of the box" targets in the cFE 6.5.0 distribution include:
     1. 32 bit x86 Linux ( CentOS 6.x )
     2. Motorola MCP750 PowerPC vxWorks 6.4

Other targets: 
    Other targets are included, but may take additional work to
    run. They are included as examples of other target 
    environments.
    1. mcf5235-rtems - This is for the Axiom MCF5235 Coldfire board running
                       RTEMS 4.10. It requires a static loader component for the
                       OS abstraction layer. The static loader is currently
                       not available as open source, so this target is not
                       considered complete. RTEMS 4.11 will have a dynamic
                       loader which will be supported by a future release
                       of the OS Abstraction Layer, completing the RTEMS support
                       for the cFE.
          
                       Once RTEMS 4.11 is released, the goal is to support
                       an RTEMS simulator platform such as SPARC/sis or 
                       quemu.

    2. mac-osx and pc-cygwin - These targets are included for examples. They
                       will most likely be removed in the future. 
                       The pc-linux target is highly recommended. If you 
                       have a windows or mac computer it is relatively easy to 
                       set up a free virtual machine environment with 32 bit 
                       Cent OS 5.x.
                       
EOF                       