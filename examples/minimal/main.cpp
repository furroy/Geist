#include <geist/Engine.h>
#include <geist/Globals.h>
#include <geist/StateMachine.h>
#include <geist/State.h>
#include <raylib.h>
#include <memory>

// Simple example state that displays "Hello Geist!"
class ExampleState : public State
{
public:
    void Init(const std::string& configfile) override
    {
        // Called once when state is created
    }

    void Shutdown() override
    {
        // Called when state is destroyed
    }

    void OnEnter() override
    {
        // Called when state is entered
    }

    void OnExit() override
    {
        // Called when state is exited
    }

    void Update() override
    {
        // Check for exit
        if (IsKeyPressed(KEY_ESCAPE))
        {
            g_Engine->m_Done = true;
        }
    }

    void Draw() override
    {
        // Clear to deep dark purple background
        ClearBackground(Color{40, 20, 60, 255});

        // Draw some text - coordinates relative to screen
        DrawText("Hello Geist!",
                 100,
                 100,
                 40, RAYWHITE);

        DrawText("Press ESC to exit",
                 10,
                 200,
                 20, LIGHTGRAY);
    }
};

int main()
{
    // Create global engine instance
    g_Engine = std::make_unique<Engine>();

    // Initialize with configuration file
    g_Engine->Init("engine.cfg");

    // Create and register our example state
    ExampleState* exampleState = new ExampleState();
    exampleState->Init("");
    g_StateMachine->RegisterState(0, exampleState, "ExampleState");
    g_StateMachine->MakeStateTransition(0);

    // Main game loop
    while (!g_Engine->m_Done && !WindowShouldClose())
    {
        g_Engine->Update();
        g_Engine->Draw();
    }

    // Cleanup
    g_Engine->Shutdown();

    return 0;
}
