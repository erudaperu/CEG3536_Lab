import importlib.util, contextlib, io
from pathlib import Path
spec=importlib.util.spec_from_file_location("telem",Path(__file__).parents[1]/"hote/telemetrie.py")
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
header="H,"+",".join(m.COLONNES)+"\r\n"
def line(t): return f"T,{t},1,1,50,50,250,24000,1,0\r\n"
def analyse(lines):
    with contextlib.redirect_stdout(io.StringIO()): return m.analyser(lines)
assert analyse([header]+[line(t) for t in (200,400,600)])==0
assert analyse([header]+[line(t) for t in (200,600,1000)])!=0
assert analyse([line(t) for t in (200,400,600)])!=0
assert analyse([header,line(200)])!=0
assert analyse([header]+[line(t).replace("\r\n","\n") for t in (200,400,600)])!=0
assert analyse([header]+[line(t) for t in (4294967200,104,304)])==0
assert analyse([header,line(200),"T,400,1,1\r\n",line(600)])!=0
print("VALIDATEUR: cadence, en-tete, minimum de trames, CRLF, rollover, troncature OK")
