#!/bin/bash
set -e

# 1. Create Android Folder Structure
mkdir -p app/src/main/java/com/zerophone/vault
mkdir -p app/src/main/res/layout
mkdir -p app/src/main/res/values

# 2. Create settings.gradle
cat << 'EOF' > settings.gradle
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "ZeroPhoneVault"
include ':app'
EOF

# 3. Create Root build.gradle
cat << 'EOF' > build.gradle
plugins {
    id 'com.android.application' version '8.2.0' apply false
    id 'org.jetbrains.kotlin.android' version '1.9.20' apply false
}
EOF

# 4. Create gradle.properties
cat << 'EOF' > gradle.properties
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
kotlin.code.style=official
android.nonTransitiveRClass=true
EOF

# 5. Create app/build.gradle
cat << 'EOF' > app/build.gradle
plugins {
    id 'com.android.application'
    id 'org.jetbrains.kotlin.android'
}

android {
    namespace 'com.zerophone.vault'
    compileSdk 34

    defaultConfig {
        applicationId "com.zerophone.vault"
        minSdk 26
        targetSdk 34
        versionCode 1
        versionName "1.0"
    }

    buildTypes {
        release {
            minifyEnabled false
        }
    }
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = '17'
    }
}

dependencies {
    implementation 'androidx.core:core-ktx:1.12.0'
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.11.0'
}
EOF

# 6. Create AndroidManifest.xml
cat << 'EOF' > app/src/main/AndroidManifest.xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <uses-permission android:name="android.permission.PACKAGE_USAGE_STATS" tools:ignore="ProtectedPermissions" />
    <uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
    <uses-permission android:name="android.permission.QUERY_ALL_PACKAGES" tools:ignore="QueryAllPackagesPermission" />

    <application
        android:allowBackup="true"
        android:label="ZeroPhone Vault"
        android:supportsRtl="true"
        android:theme="@style/Theme.AppCompat.NoActionBar">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTask"
            android:stateNotNeeded="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.HOME" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF

# 7. Create Complete Kotlin Code (All Screens in MainActivity.kt)
cat << 'EOF' > app/src/main/java/com/zerophone/vault/MainActivity.kt
package com.zerophone.vault

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.provider.Settings
import android.provider.Telephony
import android.text.Editable
import android.text.InputType
import android.text.TextWatcher
import android.view.ActionMode
import android.view.Gravity
import android.view.Menu
import android.view.MenuItem
import android.view.View
import android.widget.*
import androidx.activity.OnBackPressedCallback
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import java.util.Calendar

class MainActivity : AppCompatActivity(), SensorEventListener {

    private lateinit var prefs: android.content.SharedPreferences
    private val handler = Handler(Looper.getMainLooper())
    private var sensorManager: SensorManager? = null
    private var stepSensor: Sensor? = null
    private var emergencyStepsWalked = 0
    private var tvStepCounter: TextView? = null

    private val addictiveApps = listOf(
        "com.instagram.android",
        "com.google.android.youtube",
        "com.facebook.katana",
        "com.snapchat.android",
        "com.android.chrome",
        "in.mohalla.video"
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        prefs = getSharedPreferences("ZeroPhonePrefs", Context.MODE_PRIVATE)
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        stepSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_STEP_DETECTOR)

        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                showHomeOrContract()
            }
        })

        showHomeOrContract()
    }

    override fun onResume() {
        super.onResume()
        showHomeOrContract()
    }

    private fun showHomeOrContract() {
        val todayKey = getTodayDateKey()
        val lockedDate = prefs.getString("contract_date", "")
        if (lockedDate != todayKey) {
            renderScreen1MorningContract()
        } else {
            renderScreen2MinimalistHome()
        }
    }

    private fun getTodayDateKey(): String {
        val cal = Calendar.getInstance()
        return "${cal.get(Calendar.YEAR)}-${cal.get(Calendar.DAY_OF_YEAR)}"
    }

    // =========================================================
    // SCREEN 1: MORNING CONTRACT SETUP
    // =========================================================
    private fun renderScreen1MorningContract() {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.BLACK)
            setPadding(64, 100, 64, 64)
            gravity = Gravity.CENTER_VERTICAL
        }

        val title = TextView(this).apply {
            text = "🛡️ ZEROPHONE VAULT"
            textSize = 26f
            setTextColor(Color.WHITE)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
        }

        val sub = TextView(this).apply {
            text = "\nApne Aaj Ke Waqt Ki Keemat Tay Karein\n\n• WhatsApp Active Limit : 2 Hours Free\n  (Quick reply <30s count nahi hoga)\n\n• Reels / Vault Limit : 1 Hour Free\n  (Instagram, YouTube, FB, Chrome)\n"
            textSize = 15f
            setTextColor(Color.LTGRAY)
        }

        val penaltyLabel = TextView(this).apply {
            text = "Select Penalty Amount (If You Break Rule):"
            textSize = 16f
            setTextColor(Color.parseColor("#FFD740"))
            setPadding(0, 20, 0, 20)
        }

        var selectedPenalty = 49
        val radioGroup = RadioGroup(this).apply {
            orientation = RadioGroup.HORIZONTAL
        }

        listOf(29, 49, 99).forEach { amt ->
            val rb = RadioButton(this).apply {
                text = "  ₹$amt    "
                textSize = 18f
                setTextColor(Color.WHITE)
                id = amt
                isChecked = (amt == 49)
                setOnClickListener { selectedPenalty = amt }
            }
            radioGroup.addView(rb)
        }

        val btnPermission = Button(this).apply {
            text = "1. Grant Screen Time Permission"
            setBackgroundColor(Color.DKGRAY)
            setTextColor(Color.WHITE)
            setOnClickListener {
                startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
            }
        }

        val btnLock = Button(this).apply {
            text = "🔒 LOCK MY PHONE FOR TODAY"
            textSize = 17f
            setBackgroundColor(Color.parseColor("#D32F2F"))
            setTextColor(Color.WHITE)
            setPadding(0, 36, 0, 36)
            setOnClickListener {
                if (!hasUsageStatsPermission()) {
                    Toast.makeText(context, "Pehle Screen Time Permission On karein!", Toast.LENGTH_LONG).show()
                    startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                    return@setOnClickListener
                }
                prefs.edit()
                    .putString("contract_date", getTodayDateKey())
                    .putInt("penalty_amount", selectedPenalty)
                    .putInt("bonus_vault_mins", 0)
                    .putInt("bonus_wa_mins", 0)
                    .apply()
                renderScreen2MinimalistHome()
            }
        }

        root.addView(title)
        root.addView(sub)
        root.addView(penaltyLabel)
        root.addView(radioGroup)
        root.addView(Space(this).apply { minimumHeight = 40 })
        if (!hasUsageStatsPermission()) {
            root.addView(btnPermission)
            root.addView(Space(this).apply { minimumHeight = 24 })
        }
        root.addView(btnLock)

        setContentView(root)
    }

    // =========================================================
    // SCREEN 2: 5-BUTTON MINIMALIST HOME SCREEN
    // =========================================================
    private fun renderScreen2MinimalistHome() {
        val (vaultUsedMins, waUsedMins) = getTodayUsageMinutes()
        val vaultAllowed = 60 + prefs.getInt("bonus_vault_mins", 0)
        val waAllowed = 120 + prefs.getInt("bonus_wa_mins", 0)

        val vaultLeft = (vaultAllowed - vaultUsedMins).coerceAtLeast(0)
        val waLeft = (waAllowed - waUsedMins).coerceAtLeast(0)
        val penaltyAmt = prefs.getInt("penalty_amount", 49)

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.BLACK)
            setPadding(64, 80, 64, 64)
        }

        // Top Live Timer Box
        val statusBox = TextView(this).apply {
            text = "⏳ VAULT LEFT : ${vaultLeft}m / ${vaultAllowed}m\n🟢 WHATSAPP   : ${waLeft}m / ${waAllowed}m\n💸 PENALTY TIER: ₹$penaltyAmt"
            textSize = 14f
            typeface = Typeface.MONOSPACE
            setTextColor(if (vaultLeft == 0) Color.parseColor("#FF5252") else Color.parseColor("#69F0AE"))
            setBackgroundColor(Color.parseColor("#141414"))
            setPadding(40, 36, 40, 36)
        }
        root.addView(statusBox)
        root.addView(Space(this).apply { minimumHeight = 50 })

        // 1. CALL
        root.addView(makeMinimalButton("1. 📞  Call") {
            startActivity(Intent(Intent.ACTION_DIAL))
        })

        // 2. MESSAGES
        root.addView(makeMinimalButton("2. 💬  Messages (SMS)") {
            val smsPkg = Telephony.Sms.getDefaultSmsPackage(this)
            val intent = packageManager.getLaunchIntentForPackage(smsPkg ?: "")
            if (intent != null) startActivity(intent) else startActivity(Intent(Intent.ACTION_MAIN).apply { addCategory(Intent.CATEGORY_APP_MESSAGING) })
        })

        // 3. WHATSAPP (2-Hour Smart Rule)
        val waText = if (waLeft > 0) "3. 🟢  WhatsApp  [${waLeft}m left]" else "3. 🔒  WhatsApp  [LOCKED]"
        root.addView(makeMinimalButton(waText) {
            if (waLeft > 0) {
                launchPackage("com.whatsapp", "WhatsApp")
            } else {
                renderScreen4PenaltyLock("WhatsApp (2-Hr Limit Over)", isWhatsApp = true)
            }
        })

        // 4. UPI PAY
        root.addView(makeMinimalButton("4. 💸  UPI Pay") {
            openUpiApp()
        })

        // 5. CUSTOM 5TH APP
        val savedName = prefs.getString("fifth_name", null)
        val fifthLabel = if (savedName != null) "5. ⭐  $savedName  (Hold to change)" else "5. ➕  Add 5th Essential App"
        val fifthBtn = makeMinimalButton(fifthLabel) {
            val pkg = prefs.getString("fifth_pkg", null)
            if (pkg == null) showAppPicker(onlyEssential = true) else launchPackage(pkg, savedName ?: "App")
        }
        fifthBtn.setOnLongClickListener {
            showAppPicker(onlyEssential = true)
            true
        }
        root.addView(fifthBtn)

        root.addView(Space(this).apply { minimumHeight = 50 })

        // Faltu Notification Bar
        val notifBar = TextView(this).apply {
            text = "🔕 Silent Digest Mode Active (Unlocks at 8:00 PM)"
            textSize = 13f
            setTextColor(Color.GRAY)
            setPadding(0, 10, 0, 24)
        }
        root.addView(notifBar)

        // Open Vault Button
        val btnVault = Button(this).apply {
            text = if (vaultLeft > 0) "🔐 Open All Apps Vault (${vaultLeft}m left)" else "🛑 Vault Locked! (Pay ₹$penaltyAmt or Do Task)"
            setBackgroundColor(if (vaultLeft > 0) Color.parseColor("#1E1E1E") else Color.parseColor("#B71C1C"))
            setTextColor(Color.WHITE)
            setPadding(0, 32, 0, 32)
            setOnClickListener {
                if (vaultLeft > 0) {
                    showAppPicker(onlyEssential = false)
                } else {
                    renderScreen4PenaltyLock("1-Hour Entertainment Vault", isWhatsApp = false)
                }
            }
        }
        root.addView(btnVault)

        // Test Lock Screen Button (For Instant Testing)
        val btnTestLock = TextView(this).apply {
            text = "\n[ ⚡ Tap Here to Test Lock / Penalty Screen Now ]"
            textSize = 13f
            setTextColor(Color.parseColor("#FFD740"))
            gravity = Gravity.CENTER
            setOnClickListener {
                renderScreen4PenaltyLock("Demo Test Lock (1-Hr Over)", isWhatsApp = false)
            }
        }
        root.addView(btnTestLock)

        // Official Uninstall Gatekeeper Link
        val btnUninstall = TextView(this).apply {
            text = "\n[ ⚠️ Exit / Uninstall Gatekeeper ]"
            textSize = 12f
            setTextColor(Color.DKGRAY)
            gravity = Gravity.CENTER
            setOnClickListener { renderScreen6UninstallGatekeeper() }
        }
        root.addView(btnUninstall)

        setContentView(root)
    }

    private fun makeMinimalButton(title: String, onClick: () -> Unit): TextView {
        return TextView(this).apply {
            text = title
            textSize = 21f
            setTextColor(Color.WHITE)
            setPadding(16, 34, 16, 34)
            setOnClickListener { onClick() }
        }
    }

    // =========================================================
    // SCREEN 4: RED ALERT PENALTY LOCK SCREEN
    // =========================================================
    private fun renderScreen4PenaltyLock(lockedTarget: String, isWhatsApp: Boolean) {
        val penaltyAmt = prefs.getInt("penalty_amount", 49)

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#120000"))
            setPadding(64, 100, 64, 64)
            gravity = Gravity.CENTER
        }

        val title = TextView(this).apply {
            text = "🛑 TIME OVER BHAI!\n\n$lockedTarget\nkhatam ho chuka hai."
            textSize = 22f
            setTextColor(Color.WHITE)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
        }

        val btnHome = Button(this).apply {
            text = "🏠 Wapas Home Screen Par Jao (₹0)"
            setBackgroundColor(Color.parseColor("#2E7D32"))
            setTextColor(Color.WHITE)
            setPadding(0, 32, 0, 32)
            setOnClickListener { renderScreen2MinimalistHome() }
        }

        val btnPay = Button(this).apply {
            text = "⚡ Pay ₹$penaltyAmt via UPI -> +30 Mins"
            setBackgroundColor(Color.parseColor("#FF8F00"))
            setTextColor(Color.BLACK)
            setPadding(0, 32, 0, 32)
            setOnClickListener {
                triggerUpiPenalty(penaltyAmt, isWhatsApp)
            }
        }

        val btnEmergency = Button(this).apply {
            text = "🆘 Asli Emergency? Kadi Mehnat Karein"
            setBackgroundColor(Color.DKGRAY)
            setTextColor(Color.WHITE)
            setOnClickListener {
                renderScreen5EmergencyChallenge(isWhatsApp)
            }
        }

        root.addView(title)
        root.addView(Space(this).apply { minimumHeight = 70 })
        root.addView(btnHome)
        root.addView(Space(this).apply { minimumHeight = 32 })
        root.addView(btnPay)
        root.addView(Space(this).apply { minimumHeight = 32 })
        root.addView(btnEmergency)

        setContentView(root)
    }

    // =========================================================
    // SCREEN 5: EMERGENCY HARD WORK (500 STEPS OR 500 WORDS)
    // =========================================================
    private fun renderScreen5EmergencyChallenge(isWhatsApp: Boolean) {
        emergencyStepsWalked = 0
        stepSensor?.let { sensorManager?.registerListener(this, it, SensorManager.SENSOR_DELAY_UI) }

        val scroll = ScrollView(this).apply { setBackgroundColor(Color.BLACK) }
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(56, 80, 56, 56)
        }

        val header = TextView(this).apply {
            text = "🆘 EMERGENCY UNLOCK (+15 MINS)\nComplete ANY ONE task below:"
            textSize = 19f
            setTextColor(Color.parseColor("#FFD740"))
            typeface = Typeface.DEFAULT_BOLD
        }

        // Task 1: 500 Steps Pedometer
        tvStepCounter = TextView(this).apply {
            text = "\n🚶‍♂️ TASK 1: WALK 500 STEPS\nLive Pedometer: 0 / 500 Steps\n(Walk holding phone to unlock automatically)\n"
            textSize = 17f
            setTextColor(Color.parseColor("#69F0AE"))
        }

        // Task 2: 500 Words No-Paste Essay
        val essayLabel = TextView(this).apply {
            text = "✍️ TASK 2: TYPE 500 WORDS ESSAY\n(Copy-Paste Disabled! Write why this is urgent): 0 / 500 words"
            textSize = 15f
            setTextColor(Color.WHITE)
        }

        val editEssay = EditText(this).apply {
            hint = "Start typing here without copy-paste..."
            setHintTextColor(Color.GRAY)
            setTextColor(Color.WHITE)
            setBackgroundColor(Color.parseColor("#1A1A1A"))
            minLines = 6
            setPadding(24, 24, 24, 24)
            inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_MULTI_LINE or InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS
            customSelectionActionModeCallback = object : ActionMode.Callback {
                override fun onCreateActionMode(mode: ActionMode?, menu: Menu?) = false
                override fun onPrepareActionMode(mode: ActionMode?, menu: Menu?) = false
                override fun onActionItemClicked(mode: ActionMode?, item: MenuItem?) = false
                override fun onDestroyActionMode(mode: ActionMode?) {}
            }
        }

        val btnUnlockEssay = Button(this).apply {
            text = "🔒 Type 500 Words to Unlock"
            isEnabled = false
            setBackgroundColor(Color.DKGRAY)
            setTextColor(Color.WHITE)
            setOnClickListener {
                grantExtraTime(15, isWhatsApp)
            }
        }

        editEssay.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {
                if (count - before > 25) {
                
