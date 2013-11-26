#include "platform/tizen/TizenApplication.h"


using namespace Tizen::Graphics::Opengl;


namespace nme {
	
	
	FrameCreationCallback sgCallback;
	unsigned int sgFlags;
	int sgHeight;
	const char *sgTitle;
	TizenFrame *sgTizenFrame;
	int sgWidth;
	
	
	void CreateMainFrame (FrameCreationCallback inOnFrame, int inWidth, int inHeight, unsigned int inFlags, const char *inTitle, Surface *inIcon) {
		
		sgCallback = inOnFrame;
		sgWidth = inWidth;
		sgHeight = inHeight;
		sgFlags = inFlags;
		sgTitle = inTitle;
		
		sgWidth = 720;
		sgHeight = 720;
		
		Tizen::Base::Collection::ArrayList args (Tizen::Base::Collection::SingleObjectDeleter);
		args.Construct ();
		result r = Tizen::App::Application::Execute (TizenApplication::CreateInstance, &args);
		
	}
	
	
	void StartAnimation () {
		
		Event poll (etPoll);
		sgTizenFrame->HandleEvent (poll);
		
		/*while (!glfwWindowShouldClose(sgGLFWFrame->GetWindow()))
		{
		  glfwPollEvents();

		  int i, count;
		  for (int joy = 0; joy < MAX_JOYSTICKS; joy++)
		  {
			 if (glfwJoystickPresent(joy) == GL_TRUE)
			 {
				// printf("joystick %s\n", glfwGetJoystickName(joy));

				const float *axes = glfwGetJoystickAxes(joy, &count);
				for (i = 0; i < count; i++)
				{
					Event joystick(etJoyAxisMove);
					joystick.id = joy;
					joystick.code = i;
					joystick.value = axes[i];
					sgGLFWFrame->HandleEvent(joystick);
				}

				const unsigned char *pressed = glfwGetJoystickButtons(joy, &count);
				for (i = 0; i < count; i++)
				{
					Event joystick(pressed[i] == GLFW_PRESS ? etJoyButtonDown : etJoyButtonUp);
					joystick.id = joy;
					joystick.code = i;
					sgGLFWFrame->HandleEvent(joystick);
				}
			 }
		  }

		  Event poll(etPoll);
		  sgGLFWFrame->HandleEvent(poll);
		}*/
	}
	
	
	void PauseAnimation () {}
	void ResumeAnimation () {}
	
	
	void StopAnimation () {
		
		//GLFWwindow *window = sgGLFWFrame->GetWindow();
		//glfwDestroyWindow(window);
		//glfwTerminate();
		
	}
	
	
	TizenApplication::TizenApplication (void) {
		
		mEGLDisplay = EGL_NO_DISPLAY;
		mEGLSurface = EGL_NO_SURFACE;
		mEGLConfig = null;
		mEGLContext = EGL_NO_CONTEXT;
		mForm = null;
		mTimer = null;
		
	}
	
	
	TizenApplication::~TizenApplication (void) {}
	
	
	void TizenApplication::Cleanup (void) {
		
		if (mTimer != null) {
			
			mTimer->Cancel ();
			delete mTimer;
			mTimer = null;
			
		}

		//DestroyGL();
	}


	Tizen::App::Application* TizenApplication::CreateInstance (void) {
		
		return new (std::nothrow) TizenApplication ();
		
	}
	
	
	bool TizenApplication::OnAppInitializing (Tizen::App::AppRegistry& appRegistry) {
		
		Tizen::Ui::Controls::Frame* appFrame = new (std::nothrow) Tizen::Ui::Controls::Frame ();
		appFrame->Construct ();
		this->AddFrame (*appFrame);
		
		mForm = new (std::nothrow) TizenForm (this);
		mForm->Construct (Tizen::Ui::Controls::FORM_STYLE_NORMAL);
		GetAppFrame ()->GetFrame ()->AddControl (mForm);
		
		mForm->AddKeyEventListener (*this);
		
		bool ok = nmeEGLCreate (mForm, sgWidth, sgHeight, 2, (sgFlags & wfDepthBuffer) ? 16 : 0, (sgFlags & wfStencilBuffer) ? 8 : 0, 0);
		//AppLog ("EGL OK? %d\n", ok);
		
		mTimer = new (std::nothrow) Tizen::Base::Runtime::Timer;
		mTimer->Construct (*this);
		
		Tizen::System::PowerManager::AddScreenEventListener (*this);
		
		sgTizenFrame = new TizenFrame (sgWidth, sgHeight);
		//sgTizenFrame = createWindowFrame (inTitle, inWidth, inHeight, inFlags);
		sgCallback (sgTizenFrame);
		
		return true;
		
	}
	
	
	bool TizenApplication::OnAppTerminating (Tizen::App::AppRegistry& appRegistry, bool forcedTermination) {
		
		Cleanup ();

		return true;
		
	}
	
	
	void TizenApplication::OnBackground (void) {
		
		if (mTimer != null) {
			
			mTimer->Cancel ();
			
		}
		
	}
	
	
	void TizenApplication::OnBatteryLevelChanged (Tizen::System::BatteryLevel batteryLevel) {}
	
	
	void TizenApplication::OnForeground (void) {
		
		if (mTimer != null) {
			
			mTimer->Start (10);
			
		}
		
	}
	
	
	void TizenApplication::OnKeyLongPressed (const Tizen::Ui::Control& source, Tizen::Ui::KeyCode keyCode) {}
	
	
	void TizenApplication::OnKeyPressed (const Tizen::Ui::Control& source, Tizen::Ui::KeyCode keyCode) {
		
		
		
	}
	
	
	void TizenApplication::OnKeyReleased (const Tizen::Ui::Control& source, Tizen::Ui::KeyCode keyCode) {
		
		if (keyCode == Tizen::Ui::KEY_BACK || keyCode == Tizen::Ui::KEY_ESC) {
			
			Terminate ();
			
		}
		
	}
	
	
	void TizenApplication::OnLowMemory (void) {}
	void TizenApplication::OnScreenOn (void) {}
	void TizenApplication::OnScreenOff (void) {}
	
	
	void TizenApplication::OnTimerExpired (Tizen::Base::Runtime::Timer& timer) {
		
		if (mTimer == null) {
			
			return;
			
		}
		
		mTimer->Start (10);
		
		//AppLog("POLL\n");
		Event poll (etPoll);
		sgTizenFrame->HandleEvent (poll);
		
		/*Update();
		
		if (!Draw())
		{
			AppLog("[GlesCube] GlesCube::Draw() failed.");
		}*/
		
	}


	/*bool
	GlesCube::InitEGL(void)
	{
		EGLint numConfigs = 1;

		EGLint eglConfigList[] =
		{
			EGL_RED_SIZE,	8,
			EGL_GREEN_SIZE,	8,
			EGL_BLUE_SIZE,	8,
			EGL_ALPHA_SIZE,	8,
			EGL_DEPTH_SIZE, 8,
			EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
			EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
			EGL_NONE
		};

		EGLint eglContextList[] = 
		{
			EGL_CONTEXT_CLIENT_VERSION, 2,
			EGL_NONE
		};

		eglBindAPI(EGL_OPENGL_ES_API);

		__eglDisplay = eglGetDisplay((EGLNativeDisplayType)EGL_DEFAULT_DISPLAY);
		TryCatch(__eglDisplay != EGL_NO_DISPLAY, , "[GlesCube] eglGetDisplay() failed.");

		TryCatch(!(eglInitialize(__eglDisplay, null, null) == EGL_FALSE || eglGetError() != EGL_SUCCESS), , "[GlesCube] eglInitialize() failed.");

		TryCatch(!(eglChooseConfig(__eglDisplay, eglConfigList, &__eglConfig, 1, &numConfigs) == EGL_FALSE ||
				eglGetError() != EGL_SUCCESS), , "[GlesCube] eglChooseConfig() failed.");

		TryCatch(numConfigs, , "[GlesCube] eglChooseConfig() failed. because of matching config doesn't exist");

		__eglSurface = eglCreateWindowSurface(__eglDisplay, __eglConfig, (EGLNativeWindowType)__pForm, null);
		TryCatch(!(__eglSurface == EGL_NO_SURFACE || eglGetError() != EGL_SUCCESS), , "[GlesCube] eglCreateWindowSurface() failed.");

		__eglContext = eglCreateContext(__eglDisplay, __eglConfig, EGL_NO_CONTEXT, eglContextList);
		TryCatch(!(__eglContext == EGL_NO_CONTEXT || eglGetError() != EGL_SUCCESS), , "[GlesCube] eglCreateContext() failed.");

		TryCatch(!(eglMakeCurrent(__eglDisplay, __eglSurface, __eglSurface, __eglContext) == EGL_FALSE ||
				eglGetError() != EGL_SUCCESS), , "[GlesCube] eglMakeCurrent() failed.");

		return true;

	CATCH:
		{
			AppLog("[GlesCube] GlesCube can run on systems which supports OpenGL ES(R) 2.0.");
			AppLog("[GlesCube] When GlesCube does not correctly execute, there are a few reasons.");
			AppLog("[GlesCube]    1. The current device(real-target or emulator) does not support OpenGL ES(R) 2.0.\n"
					" Check the Release Notes.");
			AppLog("[GlesCube]    2. The system running on emulator cannot support OpenGL(R) 2.1 or later.\n"
					" Try with other system.");
			AppLog("[GlesCube]    3. The system running on emulator does not maintain the latest graphics driver.\n"
					" Update the graphics driver.");
		}

		DestroyGL();

		return false;
	}


	bool
	GlesCube::InitGL(void)
	{
	    GLint linked = GL_FALSE;
	    GLuint fragShader = glCreateShader(GL_FRAGMENT_SHADER);
	    GLuint vertShader = glCreateShader(GL_VERTEX_SHADER);

	    glShaderSource(fragShader, 1, static_cast<const char**> (&FRAGMENT_TEXT), null);
	    glCompileShader(fragShader);
	    GLint bShaderCompiled = GL_FALSE;
	    glGetShaderiv(fragShader, GL_COMPILE_STATUS, &bShaderCompiled);

	    TryCatch(bShaderCompiled != GL_FALSE, , "[GlesCube] bShaderCompiled = GL_FALSE");

	    glShaderSource(vertShader, 1, static_cast<const char**> (&VERTEX_TEXT), null);
	    glCompileShader(vertShader);
	    glGetShaderiv(vertShader, GL_COMPILE_STATUS, &bShaderCompiled);

	    TryCatch(bShaderCompiled != GL_FALSE, , "[GlesCube] bShaderCompiled == GL_FALSE");

		__programObject = glCreateProgram();
		glAttachShader(__programObject, fragShader);
		glAttachShader(__programObject, vertShader);
		glLinkProgram(__programObject);
		glGetProgramiv(__programObject, GL_LINK_STATUS, &linked);

		if (linked == GL_FALSE)
		{
			GLint infoLen = 0;
			glGetProgramiv(__programObject, GL_INFO_LOG_LENGTH, &infoLen);

			if (infoLen > 1)
			{
				char* infoLog = new (std::nothrow) char[infoLen];
				glGetProgramInfoLog(__programObject, infoLen, null, infoLog);
				AppLog("[GlesCube] Linking failed. log: %s", infoLog);
				delete [] infoLog;
			}

			TryCatch(false, , "[GlesCube] linked == GL_FALSE");
		}

		__idxPosition = glGetAttribLocation(__programObject, "a_position");
		__idxColor = glGetAttribLocation(__programObject, "a_color");
		__idxMVP = glGetUniformLocation(__programObject, "u_mvpMatrix");

		glUseProgram(__programObject);

		glEnable(GL_DEPTH_TEST);

		__angle = 45.0f;

		glDeleteShader(vertShader);
		glDeleteShader(fragShader);

		glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

		return true;

	CATCH:
		glDeleteShader(vertShader);
		glDeleteShader(fragShader);

		return false;
	}


	void
	GlesCube::DestroyGL(void)
	{
		if (__programObject)
		{
			glDeleteProgram(__programObject);
		}

		if (__eglDisplay)
		{
			eglMakeCurrent(__eglDisplay, null, null, null);

			if (__eglContext)
			{
				eglDestroyContext(__eglDisplay, __eglContext);
				__eglContext = EGL_NO_CONTEXT;
			}

			if (__eglSurface)
			{
				eglDestroySurface(__eglDisplay, __eglSurface);
				__eglSurface = EGL_NO_SURFACE;
			}

			eglTerminate(__eglDisplay);
			__eglDisplay = EGL_NO_DISPLAY;
		}

		return;
	}


	void
	GlesCube::Update(void)
	{
		FloatMatrix4 matPerspective;
		FloatMatrix4 matModelview;

		__angle += 5.0f;

		if (__angle >= 360.0f)
		{
			__angle -= 360.0f;
		}

		int x, y, width, height;
		__pForm->GetBounds(x, y, width, height);

		float aspect = float(width) / float(height);

		Perspective(&matPerspective, 60.0f, aspect, 1.0f, 20.0f);

		Translate(&matModelview, 0.0f, 0.0f, -2.5f);
		Rotate(&matModelview, __angle, 1.0f, 0.0f, 1.0f);

		__matMVP = matPerspective * matModelview;
	}


	bool
	GlesCube::Draw(void)
	{
		if (eglMakeCurrent(__eglDisplay, __eglSurface, __eglSurface, __eglContext) == GL_FALSE ||
				eglGetError() != EGL_SUCCESS)
		{
			AppLog("[GlesCube] eglMakeCurrent() failed.");

			return false;
		}

		int x, y, width, height;
		__pForm->GetBounds(x, y, width, height);

		glViewport(0, 0, width, height);

		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

		glVertexAttribPointer(__idxPosition, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GL_FLOAT), VERTICES);
		glVertexAttribPointer(__idxColor, 4, GL_FLOAT, GL_FALSE, 4 * sizeof(GL_FLOAT), COLORS);

		glEnableVertexAttribArray(__idxPosition);
		glEnableVertexAttribArray(__idxColor);

		glUniformMatrix4fv(__idxMVP, 1, GL_FALSE, (GLfloat*)__matMVP.matrix);

		glDrawElements(GL_TRIANGLES, numIndices, GL_UNSIGNED_SHORT, INDICES);

		eglSwapBuffers(__eglDisplay, __eglSurface);

	#ifdef DISPLAY_FPS
		static float     fps = 0.0f;
		static float     updateInterval = 1000.0f;
		static float     timeSinceLastUpdate = 0.0f;
		static float     frameCount = 0;
		static long long currentTick;
		static long long lastTick;
		static bool      isFirst = true;

		if (isFirst)
		{
			SystemTime::GetTicks(currentTick);
			lastTick = currentTick;
			isFirst = false;
		}

		frameCount++;
		SystemTime::GetTicks(currentTick);

		float elapsed = currentTick - lastTick;

		lastTick = currentTick;
		timeSinceLastUpdate += elapsed;

		if (timeSinceLastUpdate > updateInterval)
		{
			if (timeSinceLastUpdate)
			{
				fps = (frameCount / timeSinceLastUpdate) * 1000.f;
				AppLog("[GlesCube] FPS: %f frames/sec", fps);

				frameCount = 0;
				timeSinceLastUpdate -= updateInterval;
			}
		}
	#endif

		return true;
	}

	void
	GlesCube::Frustum(FloatMatrix4* pResult, float left, float right, float bottom, float top, float near, float far)
	{
	    float diffX = right - left;
	    float diffY = top - bottom;
	    float diffZ = far - near;

	    if ((near <= 0.0f) || (far <= 0.0f) ||
	        (diffX <= 0.0f) || (diffY <= 0.0f) || (diffZ <= 0.0f))
		{
	    	return;
		}

	    pResult->matrix[0][0] = 2.0f * near / diffX;
	    pResult->matrix[1][1] = 2.0f * near / diffY;
	    pResult->matrix[2][0] = (right + left) / diffX;
	    pResult->matrix[2][1] = (top + bottom) / diffY;
	    pResult->matrix[2][2] = -(near + far) / diffZ;
	    pResult->matrix[2][3] = -1.0f;
	    pResult->matrix[3][2] = -2.0f * near * far / diffZ;

	    pResult->matrix[0][1] = pResult->matrix[0][2] = pResult->matrix[0][3] = 0.0f;
	    pResult->matrix[1][0] = pResult->matrix[1][2] = pResult->matrix[1][3] = 0.0f;
	    pResult->matrix[3][0] = pResult->matrix[3][1] = pResult->matrix[3][3] = 0.0f;
	}

	void
	GlesCube::Perspective(FloatMatrix4* pResult, float fovY, float aspect, float near, float far)
	{
		float fovRadian = fovY / 360.0f * PI;
		float top = tanf(fovRadian) * near;
		float right = top * aspect;

		Frustum(pResult, -right, right, -top, top, near, far);
	}

	void
	GlesCube::Translate(FloatMatrix4* pResult, float tx, float ty, float tz)
	{
		pResult->matrix[3][0] += (pResult->matrix[0][0] * tx + pResult->matrix[1][0] * ty + pResult->matrix[2][0] * tz);
		pResult->matrix[3][1] += (pResult->matrix[0][1] * tx + pResult->matrix[1][1] * ty + pResult->matrix[2][1] * tz);
	    pResult->matrix[3][2] += (pResult->matrix[0][2] * tx + pResult->matrix[1][2] * ty + pResult->matrix[2][2] * tz);
	    pResult->matrix[3][3] += (pResult->matrix[0][3] * tx + pResult->matrix[1][3] * ty + pResult->matrix[2][3] * tz);
	}

	void
	GlesCube::Rotate(FloatMatrix4* pResult, float angle, float x, float y, float z)
	{
		FloatMatrix4 rotate;

		float cos = cosf(angle * PI / 180.0f);
		float sin = sinf(angle * PI / 180.0f);
		float cos1 = 1.0f - cos;

		FloatVector4 vector(x, y, z, 0.0f);
		vector.Normalize();
		x = vector.x;
		y = vector.y;
		z = vector.z;

		rotate.matrix[0][0] = (x * x) * cos1 + cos;
		rotate.matrix[0][1] = (x * y) * cos1 - z * sin;
		rotate.matrix[0][2] = (z * x) * cos1 + y * sin;
		rotate.matrix[0][3] = 0.0f;

		rotate.matrix[1][0] = (x * y) * cos1 + z * sin;
		rotate.matrix[1][1] = (y * y) * cos1 + cos;
		rotate.matrix[1][2] = (y * z) * cos1 - x * sin;
		rotate.matrix[1][3] = 0.0f;

		rotate.matrix[2][0] = (z * x) * cos1 - y * sin;
		rotate.matrix[2][1] = (y * z) * cos1 + x * sin;
		rotate.matrix[2][2] = (z * z) * cos1 + cos;

		rotate.matrix[2][3] = rotate.matrix[3][0] = rotate.matrix[3][1] = rotate.matrix[3][2] = 0.0f;
		rotate.matrix[3][3] = 1.0f;

		*pResult *= rotate;
	}*/
	
	
}
