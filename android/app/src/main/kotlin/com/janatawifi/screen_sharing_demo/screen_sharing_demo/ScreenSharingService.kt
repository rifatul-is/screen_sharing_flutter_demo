
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import com.janatawifi.screen_sharing_demo.screen_sharing_demo.R

class ScreenSharingService : Service() {
    override fun onBind(p0: Intent?): IBinder? {
        Log.d("TAG", "onBind: ")
        return null
    }

    override fun onStartCommand(intent: Intent, flags: Int, startId: Int): Int {
        System.out.println("Tag onStartCommand: ")
        startForegroundService()
        return START_STICKY
    }

    private fun startForegroundService() {
        Log.d("TAG", "startForegroundService: init")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Log.d("TAG", "startForegroundService: init 2")
            val channelId = createNotificationChannel("my_service", "My Background Service")
            val notificationBuilder = Notification.Builder(this, channelId)
            val notification = notificationBuilder.setOngoing(true)
                .setContentTitle("Screen capturing is running")
                .setContentText("Tap for more information or to stop the app.")
                // Make sure to use a proper icon
                .setSmallIcon(R.mipmap.ic_launcher)
                .setCategory(Notification.CATEGORY_SERVICE)
                .build()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                Log.d("TAG", "startForegroundService: grater then q")
                startForeground(1, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION)
            }
            else{
                startForeground(1, notification)
                Log.d("TAG", "startForegroundService: Failed to create foreground services")
            }
        }
    }

    private fun createNotificationChannel(channelId: String, channelName: String): String{
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val chan = NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_NONE)
            chan.lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            val service = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            service.createNotificationChannel(chan)
            return channelId
        }
        return ""
    }

}