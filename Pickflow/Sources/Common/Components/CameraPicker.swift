import SwiftUI
import UIKit

/// 카메라로 사진을 촬영해 JPEG `Data`로 전달하는 `UIImagePickerController` 래퍼.
///
/// 시뮬레이터처럼 카메라를 쓸 수 없는 환경에서는
/// `UIImagePickerController.isSourceTypeAvailable(.camera)`로 먼저 확인하고 사용한다.
struct CameraPicker: UIViewControllerRepresentable {
    var onImagePicked: (Data) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let parent: CameraPicker

        init(_ parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
            if let data = image?.jpegData(compressionQuality: 0.9) {
                parent.onImagePicked(data)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
