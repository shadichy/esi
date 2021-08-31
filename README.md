#     - ExtOS System Installer Project -

## Introduction

  Welcome to the officical github page of ExtOS System Installer project.
	
  ### About the OS
  
  The Extreme OS (formerly called ExtOS) is maintained by Shadichy. The os is aimed to bring minimal, portable but fast, funcional and customizable experience to the end-users. The os is minimal enough to be installed on a sd card within 4G of storage and plugged to any machine that match the requirements.
  
  Based on Arch Linux and Debian, users can choose between init systems like systemd, openrc,... Depend on purposes, users can choose different build/preset to suit their works
  ##### Features
  
  * Choosing based OS/distribution
  * Choosing init systems
  * Optional suits for office, gaming,...
  
  #### Minimum Requirements
  
  * CPU: i686/amd64 from the 2000s
  * RAM: 512MB
  * Storage: depends on installation types
  
  #### Installation Types
  
  ##### Full installaion:
      
   * Contains apps, softwares, utilities that work out-of-the-box
   * Minimum storage requires 8GB
   * Recommend RAM: 1GB
   * Rolling release
   * Graphic cards supported
      
  ##### Frugal installation
  
   * Intergrated in the live iso
   * Contains only necessary softwares
   * Minimum storage requires 2GB
   * Simple theme, [jwm](https://joewing.net/projects/jwm/) as the window manager
   * No graphic cards support, must be manually choose and install
   * Static release
   * Uses Squashfs filesystem
   * Slow upgrade speed
   * Manually configuration
   * Uses old lts kernel
  
  ### About the installer
  
  The ExtOS Sytem Installer is a ncurses-based terminal user-interface installer for ExtOS. It is based on [jorgeluiscarrillo/arch-setup](https://github.com/jorgeluiscarrillo/arch-setup), contributed and maintained by Shadichy Khang, a young developer. The setup tools are contained in the official ISO images, but also can be downloaded from archiso live environment. Contain various of choices, users can choose presets from the list best suite for them to work/play, with a *few* pre-configurations from our contributors :>
## Installation guide
  #### Videos
  
  
  
  ### First step: Download and flash the ISO
   Download the ISOs from [link](#).
    
  #### Use flash tool
    
   After downloaded, use either [Rufus](https://rufus.ie/en/), [Unetbootin](https://unetbootin.github.io/), import ISO and flash it into the destination disk
    
   #### Extract
    
   In case the above method did not work, try **Format the des disk as FAT32 filesystem**(also works with NTFS, ext2/3/4, exFAT, but not recommended), label it "**ESI**" and extract the iso contents to the destination disk
      
   #### Loopback using [GRUB](https://www.gnu.org/software/grub/)
   ##### Create menu entry
   `Ai rảnh mà làm`
   ##### Use GRUB shell
   Simply just run all `Create menu entry` commands without `menuentry {}` wrapper
  ### Second step: Để viết sau
