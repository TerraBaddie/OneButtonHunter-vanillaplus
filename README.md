# OneButtonHunter #
A very simple addon, executing the rotation of the hunter. It takes the autoshot timer into account and casts Aimed Shot and Multi Shot.    
It requires Auto Shot, Multi Shot and Aimed Shot to be on the auction bar.    

## Installing ##   
1. Download the folder and rename it into OneButtonHunter   
2. Make this macro: /run OBH:Run()
3. Spam press this macro
4. Type /obh on in chat to turn on debugger
5. Type /obh off to turn off debugger
6. Useful to see if your ranged weapon is too fast and always clipping your Aimed shot ranged weapons below 1.9 speed will not let Aimed Shot go off they are too fast!

```
OBH Debugging Enabled
OBH: Starting Auto Shot
OBH: Starting Auto Shot
OBH Debug -> AimedBase: 2.00 | Snapshot: 5 | RF: 1.00 | QS: 1.00 | Quiver: 1.10 | AS: 2.000 | NextAuto: 1.70
OBH: Skipping Aimed Shot to avoid clipping (1.70s left, need > 2.00s)
OBH: Found 'Multi-Shot' on action slot 9
OBH: Casting Multi-Shot
OBH: Starting Auto Shot
OBH: Starting Auto Shot
OBH: Starting Auto Shot
OBH: Starting Auto Shot
OBH: Starting Auto Shot
OBH: Starting Auto Shot
OBH Debug -> AimedBase: 2.00 | Snapshot: 5 | RF: 1.00 | QS: 1.00 | Quiver: 1.10 | AS: 2.000 | NextAuto: 2.81
OBH: Casting Aimed Shot (2.81s before next Auto)
OBH Debug -> AimedBase: 2.00 | Snapshot: 5 | RF: 1.00 | QS: 1.00 | Quiver: 1.10 | AS: 2.000 | NextAuto: 2.70
OBH: Skipping Aimed Shot to avoid clipping (2.70s left, need > 2.00s)
OBH: Found 'Multi-Shot' on action slot 9
OBH Debugging Disabled
```
#!!Image with chat debugger above in screenshot below not all pasted above is in screenshot though.
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/7c65df8a-390c-4af4-9a43-22bef08a000d" />

