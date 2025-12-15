// Flutter Integration Test for Firebase Test Lab
// This test class allows Flutter integration tests to run on Firebase Test Lab

package com.flappyjet.pro.flappy_jet_pro;

import androidx.test.rule.ActivityTestRule;
import dev.flutter.plugins.integration_test.FlutterTestRunner;
import io.flutter.embedding.android.FlutterActivity;
import org.junit.Rule;
import org.junit.Test;
import org.junit.runner.RunWith;

@RunWith(FlutterTestRunner.class)
public class MainActivityTest {
  @Rule
  public ActivityTestRule<FlutterActivity> rule =
      new ActivityTestRule<>(FlutterActivity.class, true, true); // true = launch activity automatically

  @Test
  public void testFlutterIntegrationTests() throws InterruptedException {
    // Wait for the activity to be fully launched and Flutter engine to initialize
    // This ensures the Flutter integration tests can run properly
    Thread.sleep(2000); // Give Flutter engine time to initialize
    
    // The FlutterTestRunner will automatically discover and run
    // tests in the integration_test directory
    // The activity is already launched by the rule above
  }
}

