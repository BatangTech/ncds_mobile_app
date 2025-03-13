<h1>🚀 How to Run the Project</h1>

<h2>🖥 Backend (FastAPI)</h2>

<ol>
  <li>Install dependencies</li>
</ol>

<pre><code>
pip install fastapi uvicorn firebase-admin google-generativeai \
    langchain-community langchain-huggingface chromadb pydantic decouple
</code></pre>

<ol start="2">
  <li>Verify dependencies and reinstall <code>python-decouple</code></li>
</ol>

<pre><code>
pip install -r requirements.txt
pip uninstall decouple python-decouple -y
pip cache purge
pip install python-decouple
</code></pre>

<ol start="3">
  <li>Set up environment variables</li>
  <p>Create a <code>.env</code> file in the backend directory and add the following:</p>
</ol>

<pre><code>
GEMINI_API_KEY=your_google_gemini_api_key
</code></pre>

<ol start="4">
  <li>Make sure your Firebase Admin SDK file is correctly placed</li>
  <p>Copy your <code>firebase-adminsdk.json</code> file into the backend directory.</p>
</ol>

<ol start="5">
  <li>Check if <code>python-decouple</code> is installed correctly</li>
</ol>

<pre><code>
python -c "from decouple import config; print('Import successful')"
</code></pre>

<ol start="6">
  <li>Run the FastAPI server</li>
</ol>

<pre><code>
python -m uvicorn main:app --host 0.0.0.0 --port 8080 --reload
</code></pre>

<hr>

<h2>📱 Frontend (Flutter)</h2>

<ol>
  <li>Install dependencies</li>
</ol>

<pre><code>
flutter pub get
</code></pre>

<ol start="2">
  <li>Set up Firebase</li>
  <p>Download your <code>google-services.json</code> file from Firebase Console and place it inside the <code>android/app/</code> directory.</p>
</ol>

<ol start="3">
  <li>Run the app on an emulator or a real device</li>
</ol>

<pre><code>
flutter run
</code></pre>

<ol start="4">
  <li>Run the app on a web browser</li>
</ol>

<pre><code>
flutter run -d chrome
</code></pre>

<hr>

<h3>📌 Notes:</h3>
<ul>
  <li>Ensure Python and Flutter are installed.</li>
  <li>If an <code>.env</code> file is required, configure it accordingly.</li>
  <li>Use your own Firebase configuration files:
    <ul>
      <li><code>firebase-adminsdk.json</code> for backend</li>
      <li><code>google-services.json</code> for frontend</li>
    </ul>
  </li>
</ul>
