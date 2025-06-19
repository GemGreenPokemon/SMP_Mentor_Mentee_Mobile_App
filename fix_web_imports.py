import os
import re

# Define the base directory
base_dir = r"C:\Users\never\AndroidStudioProjects\SMP_Mentor_Mentee_Mobile_App"
web_screens_dir = os.path.join(base_dir, "lib", "screens", "web")

# Map of relative imports to package imports
import_mappings = {
    # From web/shared files
    r"import '\.\./utils/responsive\.dart';": "import 'package:smp_mentor_mentee_mobile_app/utils/responsive.dart