"""Reproducible original campaign data. Run from any directory."""
import json
from pathlib import Path
root=Path(__file__).resolve().parents[1]/'data'
root.mkdir(exist_ok=True)
units={}
rows=[
('blade','Kiếm binh','Cận chiến',120,18,30,66,45,2.5,18,.85,'archer',['archer','medic'],0,0),
('guard','Vệ binh','Chống chịu',300,12,34,42,80,4,10,1.05,'blade',['blade'],0,0),
('archer','Cung thủ','Đánh xa',85,16,145,55,65,3,14,1.1,'guard',['guard','siege'],0,0),
('bomber','Hỏa pháo','Diện rộng',100,26,125,44,110,6,8,1.9,'blade',['blade','archer'],64,0),
('medic','Quân y','Hỗ trợ',90,0,125,52,90,5,6,1.4,'ally',[],0,22),
('siege','Phá thành','Công thành',240,35,155,32,140,7,6,2,'base',['base'],0,0)]
for r in rows:
 keys=['id','name','role','hp','damage','range','speed','cost','cooldown','cap','interval','priority','counters','splash','heal']
 units[r[0]]=dict(zip(keys,r))
 units[r[0]]['description']={'blade':'Áp sát cung thủ và quân y. Dễ bị hỏa pháo khi tụ đông.','guard':'Che chắn tuyến đầu. Cung thủ khắc chế từ xa.','archer':'Bắn qua tuyến trước; giữ khoảng cách với kiếm binh.','bomber':'Nổ bán kính 64; phá đội hình tụ ở cầu.','medic':'Hồi 22 HP cho đồng minh bị thương, không gây sát thương.','siege':'Gây gấp 3 sát thương vào căn cứ; cần quân bảo vệ.'}[r[0]]
(root/'units.json').write_text(json.dumps(units,ensure_ascii=False,indent=2))
(root/'upgrades.json').write_text(json.dumps({k:[70+i*65+j*10 for i in range(5)] for j,k in enumerate(units)},indent=2))
names=['Tân binh ra trận','Giữ hàng ngũ','Hỏa lực tiếp viện','Trạm bên sông','Hai mũi tiến quân','Đêm giữ cầu','Cung thủ mai phục','Vệ binh tiền tuyến','Lửa qua sông','Cổng đồng cỏ','Ngã ba dòng chảy','Trạm phía đông','Vành đai phòng thủ','Hai cầu tranh chấp','Pháo binh xuất trận','Vượt cửa đá','Cứu viện trạm gác','Đợt tấn công đỏ','Thế gọng kìm','Thành đôi cầu','Đổ bộ đảo xanh','Tiền đồn cát','Cầu giữa đảo','Đội quân công thành','Ba tuyến tiếp tế','Cơn sóng quân địch','Vòng vây đảo đá','Giành hai trạm','Giữ đảo cuối cùng','Bình minh tí hon']
objectives=['destroy','destroy','destroy','capture','destroy','survive','hold','destroy','capture','destroy','destroy','capture','hold','destroy','destroy','destroy','hold','survive','capture','destroy','destroy','hold','capture','destroy','capture','survive','destroy','capture','hold','destroy']
rosters=[['blade'],['blade','guard'],['blade','archer'],['blade','guard','archer'],['blade','archer','bomber'],['guard','archer','medic'],['guard','bomber','siege'],['blade','guard','medic','siege']]
stages=[]
for i in range(1,31):
 ch=(i-1)//10+1
 variant=(i-1)%10
 bridges=([6,17] if variant%3==0 else [11] if variant%3==1 else [5,12,18])
 # Never block bridge corridors, bases or strategic points.
 obstacles=[[x,y] for x,y in [(3+variant%4,7),(19-variant%3,28),(8,4+variant%3),(15,30-variant%2)] if x not in bridges]
 enemy=rosters[min((i-1)//3,len(rosters)-1)]
 objective=objectives[i-1]
 stages.append(dict(id=i,name=names[i-1],chapter=ch,chapter_name=['Đồng cỏ sông xanh','Hẻm đá hai cầu','Quần đảo bình minh'][ch-1],map_variant=variant,seed=4100+i*131,bridges=bridges,obstacles=obstacles,objective=objective,time_limit=180 if i<5 else 240 if ch<3 else 300,start_resource=180,enemy_resource=90 if i<4 else 180,income=8,enemy_income=8,base_hp=1500,enemy_roster=enemy,ai_interval=3.0 if ch==1 else 2.0 if ch==2 else 1.2,hold_seconds=35+ch*10,star_time=150 if ch==1 else 205 if ch==2 else 260,star_losses=12,movement_scale=1.0 if i<5 else 0.35,base_defense_damage=0 if i<5 else 28,base_defense_interval=1.0,base_defense_range=165,reward_first=120+8*i,reward_replay=15,difficulty=['Dễ','Vừa','Khó'][ch-1],terrain_hint=f'{len(bridges)} tuyến cầu; nước và đá chặn đường.',suggestion='Giữ vệ binh trước cung thủ. Chiếm trạm để triển khai gần đối phương.',unlock_unit={1:'archer',3:'guard',6:'medic',10:'bomber',15:'siege'}.get(i,'')))
(root/'stages.json').write_text(json.dumps(stages,ensure_ascii=False,indent=2))
vi={'play':'Chiến dịch','army':'Quân đội','upgrade':'Nâng cấp','settings':'Cài đặt','guide':'Hướng dẫn','continue':'Tiếp tục','back':'Quay lại','victory':'Chiến thắng','defeat':'Thất bại','deploy':'Triển khai','attack':'Tấn công','defend':'Phòng thủ','rally':'Tập kết','pause':'Tạm dừng','resume':'Tiếp tục trận','retry':'Chơi lại','next':'Ải tiếp theo','coins':'Tiền','destroy':'Phá căn cứ địch','capture':'Chiếm cả hai trạm','hold':'Giữ trạm đủ thời gian','survive':'Sống sót đến hết giờ','music':'Nhạc','sfx':'Hiệu ứng âm thanh','vibration':'Rung','quality':'Chất lượng','reset':'Xóa tiến độ','locked':'Chưa mở khóa','loading':'Đang đọc hồ sơ…'}
en=dict(zip(vi,['Campaign','Army','Upgrade','Settings','Guide','Continue','Back','Victory','Defeat','Deploy','Attack','Defend','Rally','Pause','Resume battle','Retry','Next stage','Coins','Destroy enemy base','Capture both posts','Hold a post long enough','Survive until timeout','Music','Sound effects','Vibration','Quality','Reset progress','Locked','Loading profile…']))
(root/'strings.json').write_text(json.dumps({'vi':vi,'en':en},ensure_ascii=False,indent=2))
