set pagination off
set confirm off
target extended-remote localhost:61234
break fsm_traiter if e->type == 2
continue
echo === Evenement Touch En reel, diagnostic acquittement ===\n
p *e
p etat
p estop_flag
x/3wu &btn_valide
x/3wu &btn_compteur
x/wx 0x42020410
x/wx 0x40012c34
x/wx 0x42021014
delete breakpoints
finish
p etat
p estop_flag
detach
quit
