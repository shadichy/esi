# - ExtOS System Installer Project -

## I. Introduction

  Welcome to the official github page of ExtOS System Installer project.
  
  **The os and the installer is still WIP**

### 1. About the OS
  
  The Extreme OS (formerly called ExtOS) is created and maintained by Shadichy. It aims to bring minimal, portable but fast, functional and customizable experience to the end-users. The OS is minimal enough to be installed on a sd card within 4GB of storage and plugged to any machine that match the requirements.
  
  Based on Arch Linux or Debian, users can choose between init systems like systemd, openrc,... Depend on purposes, users can select different build/preset to suit their works

#### Features
  
* Optional base OS/distribution
* Choices of init systems
* User-preferred suits for office, gaming,...
  
#### Minimum Requirements
  
* CPU: i686/amd64 from the 2000s
* RAM: depends on installation types (Minimum 512MB)
* Storage: depends on installation types
  
#### Installation Types
  
##### Full installation

* Contains apps, softwares, utilities that work out-of-the-box
* Minimum storage requires 8GB
* Recommend RAM: 2GB (Minimum 1GB for installed system and 2GB for live iso)
* Rolling release
* Graphic cards supported

##### Frugal installation
  
* Integrated in the live iso, copy directly to the destination
* Contains only necessary softwares
* Minimum storage requires 2GB
* At least 512MB ram (Recommend 2GB)
* Simple theme, [jwm](https://joewing.net/projects/jwm/) as window manager
* No graphic cards support, install manually
* Static release
* Uses SquashFS filesystem
* Slow upgrade speed
* Manually configuration
* Uses old lts kernel
  
### 2. About the installer
  
  The ExtOS System Installer is a ncurses-based terminal user-interface installer for ExtOS. It is based on [jorgeluiscarrillo/arch-setup](https://github.com/jorgeluiscarrillo/arch-setup), contributed and maintained by Shadichy Khang, a young developer. The setup tools are contained in the official ISO images, but also can be downloaded from archiso live environment. Offers various of choices, users can select presets from the list best suite for them or whatever they prefer to work/play, with a *few* pre-configurations from our contributors :>

## II. Installation guide

  `Will have docs soon`

#### Videos

  `Nothing here, still WIP`
  
### 1. Download and flash the ISO

   Download the ISOs from [link](https://drive.google.com/file/d/1Z3dfQ1Dbb4jeEGS-6ktaEAvszGCem8nN/view?usp=sharing).

   `Beta version, contains lots of bugs`

#### Use flash tool

   > After downloading iso file, use either [Rufus](https://rufus.ie/en/), [Unetbootin](https://unetbootin.github.io/), import ISO and flash it into the destination disk
   >
   > `Don't try this`

#### Extract

   > In case the above methods did not work, try **Format the des disk as FAT32 filesystem** (also works with NTFS, ext2/3/4, exFAT, but not recommended), label it "**ESI**" and extract the iso contents to the destination disk
   >
   > *(**Linux users**: flag destination disk/partition as bootable)*

#### Loopback using [GRUB](https://www.gnu.org/software/grub/)

   > **Create menu entry**
   >
   > `Ai rảnh mà làm`
   >
   > `WIP`

   > **Use GRUB shell**
   >
   > Simply just run all `Create menu entry` commands without `menuentry {}` wrapper

#### Load extracted iso from [GRUB](https://www.gnu.org/software/grub/)

   > **Create menu entry**
   >
   > `Ai rảnh mà làm`
   >
   > `WIP`

   > **Use GRUB shell**
   >
   > Simply just run all `Create menu entry` commands without `menuentry {}` wrapper

### 2. Để viết sau
  
## III. FAQ
  
## IV. Update dự án

  Hiện tại, preset design, server, security, devl office cho debian amd64 đã đầy đủ :))
  