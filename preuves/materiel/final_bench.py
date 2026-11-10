from pathlib import Path
import subprocess,hashlib
p=Path('output/lab3/CEG3536_Lab3_Arikan_Zuze').resolve();e=p/'preuves/materiel';gdb='/opt/st/stm32cubeide_2.2.0/plugins/com.st.stm32cube.ide.mcu.externaltools.gnu-tools-for-stm32.14.3.rel1.linux64_1.0.100.202602081740/tools/bin/arm-none-eabi-gdb'
for opt,cmds,duration in [('O0','qb',7),('O2','aqb',9)]:
 binary=p/f'build/{opt}/CEG3536_Lab3.bin';readback=e/f'flash_verification_finale_{opt}.bin';script=e/f'chargement_final_{opt}.gdb'
 script.write_text(f'set pagination off\nset confirm off\ntarget extended-remote localhost:61234\nmonitor reset\nload\nmonitor reset\ndump binary memory {readback} 0x08000000 {hex(0x8000000+binary.stat().st_size)}\ndetach\nquit\n')
 r=subprocess.run([gdb,'-q','-batch','-x',str(script),str(p/f'build/{opt}/CEG3536_Lab3.elf')],capture_output=True);(e/f'chargement_final_{opt}.log').write_bytes(r.stdout+r.stderr);r.check_returncode();assert binary.read_bytes()==readback.read_bytes()
 (e/f'empreinte_finale_{opt}.txt').write_text('Firmware et relecture identiques : '+hashlib.sha256(binary.read_bytes()).hexdigest()+'\n')
 r=subprocess.run(['python3','tmp/lab3/serial_hardware.py',str(e/f'diagnostics_finaux_{opt}.csv'),str(duration),cmds],capture_output=True);r.check_returncode()
 print(opt, '\n'.join(l for l in r.stdout.decode(errors='replace').splitlines() if l.startswith(('A,','Q,','B,'))),flush=True)
