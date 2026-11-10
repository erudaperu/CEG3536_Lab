from pathlib import Path
import re,runpy
from reportlab.pdfgen import canvas
from reportlab.lib.colors import HexColor
m=runpy.run_path('tmp/lab3/build_report.py');p=m['P']/'preuves/materiel';raw=(p/'essais_physiques.csv').read_bytes();i=raw.rfind(b'H,ticks_ms,');rows=[]
for l in raw[i:].decode(errors='replace').splitlines():
 if re.fullmatch(r'T,(?:-?\d+,){8}-?\d+',l):
  r=list(map(int,l[2:].split(',')))
  if 60000<=r[0]<=145000:rows.append(r)
c=canvas.Canvas('tmp/lab3/courbes.pdf',pagesize=(800,650));c.setFont('DejaVu-Bold',15);c.drawString(60,617,'STM32 réel - firmware final -O2');c.setFont('DejaVu',10);c.drawString(60,597,'Deux sens, rampe et E-Stop à 100 % - données série sans lissage')
left,right=65,765
X=lambda t:left+(t-60)/(145-60)*(right-left)
for bottom,height,maxy,ticks,title,series in [(430,130,110,[0,25,50,75,100],'Consigne et PWM (%)',[(3,1,'#145a87','Consigne'),(4,1,'#d76b1a','PWM')]),(250,130,400,[0,100,200,300,400],'Vitesse (tr/min)',[(6,.01,'#168571','Encodeur')]),(70,130,3.3,[0,1,2,3],'État / sens : 0 arrêt, 1 avant, 2 arrière, 3 urgence',[(1,1,'#4b448b','État'),(2,1,'#b04b73','Sens')])]:
 Y=lambda y:bottom+y/maxy*height
 c.setFont('DejaVu-Bold',10);c.setFillColor(HexColor('#183b56'));c.drawString(left,bottom+height+16,title)
 for t in ticks:
  c.setStrokeColor(HexColor('#dce4ea'));c.setLineWidth(.4);c.line(left,Y(t),right,Y(t));c.setFillColor(HexColor('#374957'));c.setFont('DejaVu',8);c.drawRightString(left-7,Y(t)-3,str(t))
 for t in range(60,146,10):
  c.setStrokeColor(HexColor('#e6ebef'));c.line(X(t),bottom,X(t),bottom+height)
  if bottom==70:c.drawCentredString(X(t),bottom-15,str(t))
 for k,(col,factor,color,label) in enumerate(series):
  c.setStrokeColor(HexColor(color));c.setLineWidth(1.25);path=c.beginPath();path.moveTo(X(rows[0][0]/1000),Y(rows[0][col]*factor))
  for r in rows[1:]:path.lineTo(X(r[0]/1000),Y(r[col]*factor))
  c.drawPath(path);c.setFillColor(HexColor(color));c.setFont('DejaVu',9);c.drawString(620+k*75,bottom+height+16,label)
 c.setStrokeColor(HexColor('#bb3344'));c.setDash(3,3);c.line(X(130),bottom,X(130),bottom+height);c.setDash()
c.setFillColor(HexColor('#374957'));c.setFont('DejaVu',9);c.drawString(left,31,'Temps depuis reset (s). Trait rouge : E-Stop observé à 130 s ; résolution de la télémétrie : 200 ms.');c.save()
(p/'courbes_moteur_provenance.txt').write_text(f'Journal essais_physiques.csv, en-tete à offset {i}, ticks60000..145000.\nDonnées sans lissage, trames complètes. E-Stop observé à ticks130000, résolution200ms.\n')
