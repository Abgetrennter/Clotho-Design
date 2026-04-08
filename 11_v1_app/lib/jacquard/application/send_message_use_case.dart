abstract class SendMessageUseCase {
  Future<void> execute({required String sessionId, required String message});
}
