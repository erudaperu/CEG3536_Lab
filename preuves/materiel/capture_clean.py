import os,termios,subprocess,select,time,json
from pathlib import Path
p=Path('output/lab3/CEG3536_Lab3_Arikan_Zuze').resolve();out=p/'preuves/materiel'
fd=os.open('/dev/ttyACM0',os.O_RDWR|os.O_NOCTTY|os.O_NONBLOCK);a=termios.tcgetattr(fd);a[0]=a[1]=a[3]=0;a[2]=termios.CS8|termios.CREAD|termios.CLOCAL;a[4]=a[5]=termios.B115200;a[6][termios.VMIN]=a[6][termios.VTIME]=0;termios.tcsetattr(fd,termios.TCSANOW,a);termios.tcflush(fd,termios.TCIFLUSH)
gdb='/opt/st/stm32cubeide_2.2.0/plugins/com.st.stm32cube.ide.mcu.externaltools.gnu-tools-for-stm32.14.3.rel1.linux64_1.0.100.202602081740/tools/bin/arm-none-eabi-gdb'
start=time.monotonic();r=subprocess.run([gdb,'-q','-batch','-ex','target extended-remote localhost:61234','-ex','monitor reset','-ex','detach'],capture_output=True);(out/'reset_capture.log').write_bytes(r.stdout+r.stderr)
data=bytearray();chunks=[]
while time.monotonic()-start<30.2:
 if select.select([fd],[],[],.05)[0]:
  b=os.read(fd,8192)
  if b:data.extend(b);chunks.append({'elapsed':round(time.monotonic()-start,6),'ascii':b.decode('ascii','replace')})
os.close(fd);(out/'serie_reelle_30s_brut.csv').write_bytes(data);(out/'serie_reelle_30s.timestamps.json').write_text(json.dumps(chunks,indent=2))
# Preserve raw data; the analysis window starts at the actual header after reset.
i=data.find(b'H,');selected=data[i:] if i>=0 else data
if not selected.endswith(b'\n'):selected=selected[:selected.rfind(b'\n')+1]
(out/'serie_reelle_30s.csv').write_bytes(selected)
print('Recorded',len(selected.splitlines()),'complete lines; raw data and receive timestamps retained.')
