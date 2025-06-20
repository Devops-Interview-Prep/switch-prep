1. whoami
2. date
3. pwd
4. ls
5. ls -lt
6. ls -lah ( human redable size)
7. clear
8. cat
9. cat file1 file2 (combine both the files)
10. tee ( reads std input and copies to std output and a file)
    1.  ls | tee file
11. xargs ( for commands that uses args )
    1.  ls | xargs echo
12. less (open file in editor mode)
   1.  /word ( to find word and press n to search next entry)
   2.  ?word (bottom to top)
13. more file (see content page by page)
14. touch
15. touch file{1..10}
16. rm 
17. vi
18. nano
19. mkdir
20. rm -rf
21. cd
22. pwd
23. cd / ( root directory)
24. cp
25. cp fileA fileB ( copy content of fileA in fileB)
26. mv ( we can use it for renaming too)
27. head -n file ( display top n lines)
28. tail -n file (display bottom n lines)
29. sort file
30. sort -r file ( sort in reverse order)
31. sort file | uniq (uniq content display)
32. split -l n file (split the file in n different files)
33. grep "word" file
34. egrep "word1|word2" file (search multiple words)
35. ls file*
36. wc -l file
37. cmp fileA fileB ( compare both files )
38. diff -u fileA fileB
39. find /path/ -name file
40. sudo updatedb
    1.  locate file
41. history
42. comand man (get the manual of command)
43. which comand ( what this command excutes )
44. bc ( for basic calculation)
45. cal month year ( to see of calender)
46. uptime (server uptime)
47. alias
48. gzip -k file ( compress file in zip, k -> keep the original)
49. gzip -d file or gunzip file (decompress)
50. tar -czf file.tar.gz folder ( will compress folder in file.tar.gz )
51. tar -xzf file.tar.gz ( decompress folder)
52. zip files.zip file1 file2
53. unzip -l files.zip
54. wget url (download file from internet)
55. wget -o output.txt url ( save in ouput.txt)
56. curl 
57. apt(ubuntu) or yum/dnf (redhat based like centos fedora)
58. rpm -qa | grep app ( list if the app alrady installed)
59. dnf list installed ( will give list of installed packages )
60. list available pacakges 
    1.  apt search *package name* - ubuntu
    2.  yum/dnf list available  - redhat 
61. systemctl start/stop service_name ( start or stop a service)
62. systemctl status service_name
63. systemctl list-units --type=service --all
64. printenv
65. awk -F ,'{print $n}' file.csv ( print a specific column of csv file )
    1.  $NF -> for last column
    2.  $1, $2 -> multiple columns
66. cut -cn1-n2 file ( display n1 and n2 characters of all lines )
67. sed -n '5p' file (display 5th line of file)
68. sed -n 's/word1/word2/g' file (replace word1 from word2)
69. tr [:lower:] [:upper:] < file (conver all lowercase to upper)
70. tr [:upper:] [:lower:] < file
71. truncate -s size file ( truncate the file size)
72. su 
73. chmod
74. scp
75. chown new_owner file
76. chgrp new_group file
77. free -h ( check free ram )
78. top (% cpu and mem utilization)
79. du -h ( disk utilization)
80. df -h (file system available and diskspace used)
81. hostname
82. arch
83. lsblk (list of storage devices, disk partition)
84. uname -a ( os name )
    1.  cat /etc/os-release
85. ps -ef ( running process )
86. pgrep process ( pid of a process )
87. kill -9 pid
88. pkill process_name
89. jobs (see active jobs -> tasks given to terminal)
90. bg (resume a job in background)
91. fg ( resume a job in forground)
92. nohup ./script >dev/null & ( run a script in bg)
93. ping ( to check connectivity to internet)
94. telnet ip port
95. netstat -putan | grep port ( check if port is open or not)
96. traceroute (check all hubs in network path to reach website)
97. reboot
98. shutdown
99.  useradd user_name
100. passwd user_name ( change password of user)
101. passwd -e user_name ( set force password on first login )
102. groupadd
103. id user
104. userdel ( delete user)
105. groupdel
106. usermod (modify user)
107. at time (execute particular command at that time)
108. comand > output_file
109. command >> output_file ( append in output file)
110. nice (sets priority of process)
111. quato ( display disk usage and limits for a user)


# VIM EDITOR 
- G -> to reach last line   
- gg -> to reach top line    
- u -> undo 
- ctrl + r -> redo
- o -> next line input
- O -> input above line 
- I -> start in line 
- A -> end in line 
- x -> delete character
- n dd -> cut n lines
- p -> paste
- V -> select ( use v for usual mode and select ) + y (to copy)
- :set nu ( put line numbers)
- :set nonu ( remove numbers)
- :syntax on ( colur scheme)
- :100 ( come to line number)
- vim -o file1 file2 

