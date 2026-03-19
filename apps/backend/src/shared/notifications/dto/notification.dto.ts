export class NotificationDto {
  id: string;
  title: string;
  body: string;
  type: string;
  targetId: string | null;
  createdAt: Date;
  isRead: boolean;
}
