from pathlib import Path
import re,runpy
from reportlab.pdfgen import canvas
from reportlab.lib.colors import HexColor
m=runpy.run_path('tmp/lab3/build_report.py');p=m['P']/'preuves/materiel';raw=(p/'essais_physiques.csv').read_bytes();offset=raw.rfind(b'H,ticks_ms,');rows=[]
for l in raw[offset:].decode(errors='replace').splitlines():
 if re.fullmatch(r'T,(?:-?\d+,){8}-?\d+',l):
  r=list(map(int,l[2:].split(',')))
  if 240000<=r[0]<=360000:rows.append(r)
end=rows[-1][0]/1000;c=canvas.Canvas('tmp/lab3/temperature.pdf',pagesize=(800,400));c.setFont('DejaVu-Bold',15);c.drawString(60,365,'Réponse thermique réelle - S2 interne');c.setFont('DejaVu',10);c.drawString(60,345,'Capteur tenu entre deux doigts, durée de 30 s déclarée par l’opérateur ; calibration initiale conservée')
X=lambda t:65+(t-240)/(end-240)*700;Y=lambda v:70+(v-24)/7*240
for t in range(240,int(end)+1,10):c.setStrokeColor(HexColor('#e0e7ee'));c.line(X(t),70,X(t),310);c.setFont('DejaVu',8);c.drawCentredString(X(t),55,str(t))
for v in range(24,32):c.setStrokeColor(HexColor('#dce4ea'));c.line(65,Y(v),765,Y(v));c.drawRightString(55,Y(v)-3,str(v))
c.setStrokeColor(HexColor('#d76b1a'));c.setLineWidth(1.4);path=c.beginPath();path.moveTo(X(rows[0][0]/1000),Y(rows[0][5]/10))
for r in rows[1:]:path.lineTo(X(r[0]/1000),Y(r[5]/10))
c.drawPath(path);c.setFont('DejaVu',9);c.drawString(65,25,'Temps depuis reset (s) ; ordonnée : °C indiqués. Aucun thermomètre de référence : précision absolue non validée.');c.save()
(p/'chauffage_capteur.csv').write_bytes(raw[offset:].splitlines(keepends=True)[0]+b''.join(('T,'+','.join(map(str,r))+'\r\n').encode() for r in rows))
(p/'chauffage_provenance.txt').write_text(f'Extrait des trames du journal continu, boot offset{offset}, ticks240000..360000. Valeurs identiques ; CRLF conservé.\nMinimum {min(r[5] for r in rows)/10} °C ; maximum {max(r[5] for r in rows)/10} °C.\n')
print('Temperature range:',min(r[5] for r in rows)/10,max(r[5] for r in rows)/10)
