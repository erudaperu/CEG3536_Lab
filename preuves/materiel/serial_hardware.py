import os,termios,select,time,sys,json
from pathlib import Path
out=Path(sys.argv[1]);duration=float(sys.argv[2]);commands=sys.argv[3] if len(sys.argv)>3 else ''
fd=os.open('/dev/ttyACM0',os.O_RDWR|os.O_NOCTTY|os.O_NONBLOCK)
a=termios.tcgetattr(fd);a[0]=0;a[1]=0;a[2]=termios.CS8|termios.CREAD|termios.CLOCAL;a[3]=0;a[4]=a[5]=termios.B115200;a[6][termios.VMIN]=0;a[6][termios.VTIME]=0;termios.tcsetattr(fd,termios.TCSANOW,a);termios.tcflush(fd,termios.TCIFLUSH)
drain_end=time.monotonic()+0.5
while time.monotonic()<drain_end:
 if select.select([fd],[],[],.05)[0]: os.read(fd,8192)
termios.tcflush(fd,termios.TCIFLUSH)
start=time.monotonic();data=bytearray();chunks=[];sent=0
while time.monotonic()-start<duration:
 t=time.monotonic()-start
 if sent<len(commands) and t>=2+sent*2:
  os.write(fd,commands[sent].encode());sent+=1
 if select.select([fd],[],[],.1)[0]:
  b=os.read(fd,8192)
  if b:data.extend(b);chunks.append({'elapsed':round(time.monotonic()-start,6),'ascii':b.decode('ascii','replace')})
os.close(fd);out.write_bytes(data);out.with_suffix('.timestamps.json').write_text(json.dumps(chunks,indent=2));print(bytes(data).decode('ascii','replace'))
