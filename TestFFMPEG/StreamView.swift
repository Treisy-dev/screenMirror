import SwiftUI
import GoogleCast

struct StreamView: View {
    @State private var isServerRunning = false
    let receiverPageURL = "http://192.168.31.168:8085/"

    var body: some View {
        VStack(spacing: 20) {
            Text("Локальный сервер")
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.center)

            Text("Ссылка на Receiver:")
                .font(.headline)

            Text(receiverPageURL)
                .foregroundColor(.blue)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)

            // Стандартная кнопка Cast для выбора устройства
            CastButton()

            Button("Start Casting") {
                startCasting()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)

            Button(action: {
                isServerRunning.toggle()
            }) {
                Text(isServerRunning ? "Остановить сервер" : "Запустить сервер")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isServerRunning ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }

            ProgressView()
                .padding(.top, 40)

            Spacer()
        }
        .padding()
    }

    /// Функция отправки команды загрузки медиа (HTML-страницы) на кастинговое устройство.
    private func startCasting() {
        guard let session = GCKCastContext.sharedInstance().sessionManager.currentCastSession else {
            print("Нет активной Cast-сессии")
            return
        }

        guard let mediaURL = URL(string: receiverPageURL) else {
            print("Неверный URL")
            return
        }

        // Создаем метаданные для отображения (например, заголовок)
        let metadata = GCKMediaMetadata(metadataType: .movie)
        metadata.setString("Screen Mirror", forKey: kGCKMetadataKeyTitle)

        // Строим объект информации о медиа, указывающий на вашу HTML-страницу
        let builder = GCKMediaInformationBuilder(contentURL: mediaURL)
        builder.contentType = "text/html"  // MIME-тип для HTML-страницы
        builder.streamType = .live       // Поток обновляется в режиме live, так как JS постоянно запрашивает новые кадры
        builder.metadata = metadata
        let mediaInfo = builder.build()

        // Загружаем медиа на устройство
        let options = GCKMediaLoadOptions()
        session.remoteMediaClient?.loadMedia(mediaInfo, with: options)
    }
}

struct CastButton: UIViewRepresentable {
    func makeUIView(context: Context) -> GCKUICastButton {
        // Создаем кнопку с нужным фреймом
        let button = GCKUICastButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        return button
    }

    func updateUIView(_ uiView: GCKUICastButton, context: Context) {
        // Если нужно, обновляем свойства кнопки здесь
    }
}
