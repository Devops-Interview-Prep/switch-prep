1. echo 
   1. echo "Hello"              # Hello (with newline)
   2. echo -n "Hello"           # Hello (no newline)
   3. echo -e "Line1\nLine2"    # Prints two lines
      1. \n	New line
      2. \t	Tab
      3. \\	Backslash
      4. \a	Alert (bell sound)
      5. \b	Backspace
      6. \r	Carriage return
   4. echo -e "Tab\tSeparated"  # Tab separated output
   5. echo -E "No\nInterpret"   # Prints: No\nInterpret
2. whoami
3. date
4. pwd
5. ls
6. ls -lt
7. ls -lah ( human redable size)
8. clear
9.  cat
10. cat file1 file2 (combine both the files)
11. tee ( reads std input and copies to std output and a file)
    1.  ls | tee file
12. xargs ( for commands that uses args )
    1.  ls | xargs echo
13. less (open file in editor mode)
   1.  /word ( to find word and press n to search next entry)
   2.  ?word (bottom to top)
14. more file (see content page by page)
15. touch
16. touch file{1..10}
17. rm 
18. vi
19. nano
20. mkdir
    1.  mkdir -p ( checks if the dir already exist , if not then create it)
    2.  mkdir -m 755 mydir (give permissions while creating the dir)
    3.  mkdir -v ( shows what has been created )
21. rm -rf
22. cd
23. pwd
24. cd / ( root directory)
25. cp
26. cp fileA fileB ( copy content of fileA in fileB)
27. mv ( we can use it for renaming too)
    1.  mv dir_1 dir_2 dir_3 new_dir/
28. head -n file ( display top n lines)
29. tail -n file (display bottom n lines)
30. sort file
31. sort -r file ( sort in reverse order)
32. sort file | uniq (uniq content display)
33. split -l n file (split the file in n different files)
34. grep "word" file
35. egrep "word1|word2" file (search multiple words)
36. ls file*
37. wc -l file
38. cmp fileA fileB ( compare both files )
39. diff -u fileA fileB
40. find /path/ -name file
41. sudo updatedb
    1.  locate file
42. history
43. comand man (get the manual of command)
44. which comand ( what this command excutes )
45. bc ( for basic calculation)
46. cal month year ( to see of calender)
47. uptime (server uptime)
48. alias
49. gzip -k file ( compress file in zip, k -> keep the original)
50. gzip -d file or gunzip file (decompress)
51. tar -czf file.tar.gz folder ( will compress folder in file.tar.gz )
52. tar -xzf file.tar.gz ( decompress folder)
53. zip files.zip file1 file2
54. unzip -l files.zip
55. wget url (download file from internet)
56. wget -o output.txt url ( save in ouput.txt)
57. curl 
58. apt(ubuntu) or yum/dnf (redhat based like centos fedora)
59. rpm -qa | grep app ( list if the app alrady installed)
60. dnf list installed ( will give list of installed packages )
61. list available pacakges 
    1.  apt search *package name* - ubuntu
    2.  yum/dnf list available  - redhat 
62. systemctl start/stop service_name ( start or stop a service)
63. systemctl status service_name
64. systemctl list-units --type=service --all
65. printenv
66. awk -F ,'{print $n}' file.csv ( print a specific column of csv file )
    1.  $NF -> for last column
    2.  $1, $2 -> multiple columns
67. cut 
    1.  cut -cn1-n2 file ( display n1 to n2 characters of all lines )
    2.  cut -cn1,n2 (display n1 and n2 characters)
    3.  cut -d, -f 1- file --output-delimeter=":" (Change the delimeter)
68. sed -n '5p' file (display 5th line of file)
69. sed -n 's/word1/word2/g' file (replace word1 from word2)
70. tr [:lower:] [:upper:] < file (conver all lowercase to upper)
71. tr [:upper:] [:lower:] < file
72. truncate -s size file ( truncate the file size)
73. su 
74. chmod
75. scp
76. chown new_owner file
77. chgrp new_group file
78. free -h ( check free ram )
79. top (% cpu and mem utilization)
    1.  top -b (non interactive mode/ batch mode)
    2.  top -n1 (till 1 iteration)
80. du -h ( disk utilization)
81. df -h (file system available and diskspace used)
82. hostname
83. arch
84. lsblk (list of storage devices, disk partition)
85. uname -a ( os name )
    1.  cat /etc/os-release
86. ps -ef ( running process )
87. pgrep process ( pid of a process )
88. kill -9 pid
89. pkill process_name
90. jobs (see active jobs -> tasks given to terminal)
91. bg (resume a job in background)
92. fg ( resume a job in forground)
93. nohup ./script >dev/null & ( run a script in bg)
94. ping ( to check connectivity to internet)
95. telnet ip port
96. netstat -putan | grep port ( check if port is open or not)
97. traceroute (check all hubs in network path to reach website)
98. reboot
99.  shutdown
100. useradd user_name
101. passwd user_name ( change password of user)
102. passwd -e user_name ( set force password on first login )
103. groupadd
104. id user
105. userdel ( delete user)
106. groupdel
107. usermod (modify user)
108. at time (execute particular command at that time)
109. comand > output_file
110. command >> output_file ( append in output file)
111. nice (sets priority of process)
112. quota ( display disk usage and limits for a user)
113. shred --rmove file (permanently delete a file )
114. file file_name ( to find the type of a file)









