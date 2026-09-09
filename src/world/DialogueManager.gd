class_name DialogueManager
extends RefCounted

## Quản lý Lore, Hội thoại NPC qua 4 World (Phần B Detail.md)
## Safe Haven X.9: Lão Thợ Rèn Vulcan (xuyên suốt), Bà Góa Chuông Gió (W1), Thầy Lang Điên (W2), Kỹ Sư Sao Chép (W3), Gương Phản Chiếu (W4)

static func get_dialogue_for_haven(world_idx: int) -> Array[Dictionary]:
	match world_idx:
		1:
			return [
				{ "speaker": "Bà Góa Chuông Gió", "text": "Thống Lĩnh Thiết Vệ nơi cổng thành... chàng ấy từng là người bảo vệ trung thành nhất trước khi lời nguyền phản loạn biến chàng thành quái vật." },
				{ "speaker": "Vulcan Tàn Diệt", "text": "Thanh song đao của ngươi... ta nhận ra đường nét của nó. Hãy đưa ta phôi quặng, ta sẽ đánh thức bản ngã của thép." }
			]
		2:
			return [
				{ "speaker": "Thầy Lang Điên", "text": "Ký sinh... chúng không phải dịch bệnh, chúng là sự tiến hóa thất bại của vương quốc này! Ngươi có muốn mua độc dược để cường hóa nhát chém không?" },
				{ "speaker": "Vulcan Tàn Diệt", "text": "Nơi cống ngầm ẩm mốc này từng là phòng thí nghiệm hoàng gia bí mật... sự suy tàn đã bắt đầu từ lòng tham ở đây." }
			]
		3:
			return [
				{ "speaker": "Kỹ Sư Sao Chép", "text": "Cảnh báo hệ thống: Lỗi không thể sửa chữa. Kẻ Hành Quyết được chế tạo để tiêu diệt mọi khiếm khuyết... kể cả những người đã tạo ra nó." },
				{ "speaker": "Vulcan Tàn Diệt", "text": "Bánh răng và hơi nước không thể thay thế linh hồn con người. Hãy mài sắc đao kiếm, trận chiến cuối cùng đang ở rất gần." }
			]
		4:
			return [
				{ "speaker": "Gương Phản Chiếu (Bản Ngã)", "text": "Ngươi đã đi qua 4 tầng ký ức... Ngươi nghĩ ngươi đang cứu rỗi ai? Hãy nhìn vào lưỡi đao của mình đi, kẻ phản bội lời thề thực sự... chính là ngươi!" }
			]
		_:
			return []
