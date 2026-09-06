from pathlib import Path
import shutil
b=Path('work/vx94_transform_stores_v2');(b/'review').mkdir(exist_ok=True);shutil.copy2('work/vx94_transform_stores_v1/review/project.godot',b/'review/project.godot')
s=Path('work/vx94_transform_stores_v1/review/review.gd').read_text().replace('vx94_transform_stores_v1','vx94_transform_stores_v2').replace('var exposure:=0','var exposure:=0\n\tvar route:="bomber"\n\tvar state:="loaded"').replace('textures[kind+"_%02d"%exposure]','textures[route+"_"+kind+"_"+state+"_%02d"%exposure]').replace('"VX-94 / SWIVEL PYLONS / EXPOSURE %02d"%exposure','route+" / "+state+" / EXPOSURE %02d"%exposure')
start=s.index('\tfor kind in ["hunter_rack"',s.index('func review'))
end=s.index('\tvar sequence:',start)
s=s[:start]+'''\tvar data=JSON.parse_string(FileAccess.get_file_as_string(BASE+"manifest.json"))
\tfor e in data.entries:s.textures[e.id]=ImageTexture.create_from_image(Image.load_from_file(BASE+"composites/"+e.id+".png"))
'''+s[end:]
start=s.index('\tfor i in 60:');s=s[:start]+'''\tvar frame:=0
\tfor route in ["bomber","hypersonic"]:
\t\tfor state in ["loaded","left_expended","empty"]:
\t\t\ts.route=route;s.state=state
\t\t\tfor i in 60:
\t\t\t\ts.exposure=sequence[i/2];s.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
\t\t\t\troot.get_texture().get_image().save_png(BASE+"native/frame_%03d.png"%frame);frame+=1
\tprint("VX94_TRANSFORM_STORES: 360 forward/reverse fixture captures, twelve sequences")
\tquit()
'''
(b/'review/review.gd').write_text(s)
