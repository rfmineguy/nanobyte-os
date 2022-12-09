# Disk Layout
![](http://1.bp.blogspot.com/-dZ7UokdXvxk/UzfgF2bnD3I/AAAAAAAAUs0/Zudv1JOX7AU/s1600/HD_struct.png)


# Data Access Schemes
CHS (Cylinder-Head-Sector)
  + Addressing scheme for refrencing a physical data location on a disk
  + We don't really care exactly where a piece of data is though (this is were LBA comes in)
  
LBA (Logical Block Addressing)
  + Only need one number to reference a block on the disk
  + Disk controller only deals with CHS scheme
    - Thus we will need to convert from LBA to CHS when accessing the disk

# Drive Controller
  + Disks technically don't have cylinders, heads, or sectors anymore but they are still interfaced like such

# Conversion from LBA to CHS
  `SPT = sectors per track/cylinder (on a single side)` <br>
  `HPC = heads per cylinder` <br>
  `sector # = (LBA % SPT) + 1` <br>
  `head # = (LBA / SPT) % HPC` <br>
  `cylinder # = (LBA / SPT) / HPC` <br>
