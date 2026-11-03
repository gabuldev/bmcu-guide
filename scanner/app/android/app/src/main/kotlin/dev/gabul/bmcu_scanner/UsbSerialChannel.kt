package dev.gabul.bmcu_scanner

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import com.hoho.android.usbserial.driver.UsbSerialPort
import com.hoho.android.usbserial.driver.UsbSerialProber
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/// Porta serial crua para o Dart. O protocolo de gravacao fica todo no
/// pacote bmcu_flash; aqui so tem abrir, linhas DTR/RTS, ler e escrever.
class UsbSerialChannel(private val context: Context, messenger: BinaryMessenger) {
    private val usb = context.getSystemService(Context.USB_SERVICE) as UsbManager
    private val channel = MethodChannel(messenger, "bmcu_scanner/usb")
    private val main = Handler(Looper.getMainLooper())

    // Uma thread so: as chamadas de E/S bloqueiam e precisam sair em ordem.
    private val io = Executors.newSingleThreadExecutor()
    private var port: UsbSerialPort? = null

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "list" -> result.success(list())
                // Firmware de teste copiado com adb push, sem precisar de permissao.
                "testFirmwarePath" -> result.success(
                    java.io.File(context.getExternalFilesDir(null), "test_firmware.bin").absolutePath,
                )
                "open" -> open(call.argument<String>("id")!!, result)
                else -> io.execute { run(call, result) }
            }
        }
    }

    private fun list(): List<Map<String, Any>> {
        val prober = UsbSerialProber.getDefaultProber()
        return usb.deviceList.values
            .filter { prober.probeDevice(it) != null }
            .map {
                mapOf(
                    "id" to it.deviceName,
                    "vid" to it.vendorId,
                    "pid" to it.productId,
                    "name" to (it.productName ?: it.deviceName),
                )
            }
    }

    private fun open(id: String, result: MethodChannel.Result) {
        val device = usb.deviceList[id]
        if (device == null) {
            result.error("not_found", "dispositivo USB sumiu", null)
            return
        }
        if (usb.hasPermission(device)) {
            io.execute { connect(device, result) }
            return
        }
        // Pede a permissao e so conecta quando a pessoa aceitar.
        val action = "${context.packageName}.USB_PERMISSION"
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(ctx: Context, intent: Intent) {
                context.unregisterReceiver(this)
                if (intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)) {
                    io.execute { connect(device, result) }
                } else {
                    result.error("denied", "permissao USB negada", null)
                }
            }
        }
        val filter = IntentFilter(action)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(receiver, filter)
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0
        val intent = Intent(action).setPackage(context.packageName)
        usb.requestPermission(device, PendingIntent.getBroadcast(context, 0, intent, flags))
    }

    private fun connect(device: UsbDevice, result: MethodChannel.Result) {
        try {
            closePort()
            val driver = UsbSerialProber.getDefaultProber().probeDevice(device)
                ?: throw IllegalStateException("sem driver para ${device.deviceName}")
            val connection = usb.openDevice(device)
                ?: throw IllegalStateException("nao abriu ${device.deviceName}")
            val p = driver.ports[0]
            p.open(connection)
            p.setParameters(115200, 8, UsbSerialPort.STOPBITS_1, UsbSerialPort.PARITY_NONE)
            // Mesmo estado inicial do BMCU Flasher.
            p.dtr = true
            p.rts = true
            port = p
            reply(result, null)
        } catch (e: Exception) {
            fail(result, e)
        }
    }

    private fun run(call: MethodCall, result: MethodChannel.Result) {
        try {
            val p = port
            if (call.method == "close") {
                closePort()
                return reply(result, null)
            }
            if (p == null) throw IllegalStateException("porta fechada")
            when (call.method) {
                "setBaud" -> p.setParameters(
                    call.argument<Int>("baud")!!, 8, UsbSerialPort.STOPBITS_1, UsbSerialPort.PARITY_NONE,
                )
                "setDtr" -> p.dtr = call.argument<Boolean>("value")!!
                "setRts" -> p.rts = call.argument<Boolean>("value")!!
                "write" -> p.write(call.argument<ByteArray>("data")!!, 1000)
                "read" -> {
                    val buf = ByteArray(4096)
                    val n = p.read(buf, call.argument<Int>("timeout")!!.coerceAtLeast(1))
                    return reply(result, buf.copyOf(maxOf(n, 0)))
                }
                "purge" -> try {
                    p.purgeHwBuffers(true, true)
                } catch (_: UnsupportedOperationException) {
                    // Nem todo driver sabe limpar; o parser ignora restos.
                }
                else -> return main.post { result.notImplemented() }.let {}
            }
            reply(result, null)
        } catch (e: Exception) {
            fail(result, e)
        }
    }

    private fun closePort() {
        try {
            port?.close()
        } catch (_: Exception) {
        }
        port = null
    }

    private fun reply(result: MethodChannel.Result, value: Any?) = main.post { result.success(value) }.let {}

    private fun fail(result: MethodChannel.Result, e: Exception) =
        main.post { result.error("io", e.message ?: e.toString(), null) }.let {}

    fun dispose() {
        io.execute { closePort() }
        io.shutdown()
    }
}
