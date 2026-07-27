~$ ping -D -c 10 yahoo.com
PING yahoo.com (98.137.11.164) 56(84) bytes of data.
[1785174782.322495] 64 bytes from media-router-fp73.prod.media.vip.gq1.yahoo.com (98.137.11.164): icmp_seq=1 ttl=51 time=295 ms
[1785174783.287253] 64 bytes from media-router-fp73.prod.media.vip.gq1.yahoo.com (98.137.11.164): icmp_seq=2 ttl=51 time=293 ms
[1785174784.295931] 64 bytes from media-router-fp73.prod.media.vip.gq1.yahoo.com (98.137.11.164): icmp_seq=3 ttl=51 time=300 ms
[1785174785.291325] 64 bytes from media-router-fp73.prod.media.vip.gq1.yahoo.com (98.137.11.164): icmp_seq=4 ttl=51 time=293 ms
[1785174786.293468] 64 bytes from media-router-fp73.prod.media.vip.gq1.yahoo.com (98.137.11.164): icmp_seq=5 ttl=51 time=294 ms
[1785174787.291020] 64 bytes from media-router-fp73.prod.media.vip.gq1.yahoo.com (98.137.11.164): icmp_seq=6 ttl=51 time=290 ms
[1785174788.294127] 64 bytes from media-router-fp73.prod.media.vip.gq1.yahoo.com (98.137.11.164): icmp_seq=7 ttl=51 time=292 ms
[1785174789.295731] 64 bytes from media-router-fp73.prod.media.vip.gq1.yahoo.com (98.137.11.164): icmp_seq=8 ttl=51 time=292 ms
[1785174790.294655] 64 bytes from media-router-fp73.prod.media.vip.gq1.yahoo.com (98.137.11.164): icmp_seq=9 ttl=51 time=290 ms
[1785174791.295013] 64 bytes from media-router-fp73.prod.media.vip.gq1.yahoo.com (98.137.11.164): icmp_seq=10 ttl=51 time=289 ms

--- yahoo.com ping statistics ---
10 packets transmitted, 10 received, 0% packet loss, time 9013ms
rtt min/avg/max/mdev = 289.192/292.868/299.565/2.883 ms