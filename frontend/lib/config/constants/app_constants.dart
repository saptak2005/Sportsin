/// Constants for the SportsIN app
class AppConstants {
  // User Types
  static const String userTypePlayer = 'player';
  static const String userTypeRecruiter = 'recruiter';
  static const List<String> userTypes = [userTypePlayer, userTypeRecruiter];

  // Gender options
  static const List<String> genders = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say'
  ];

  // Age group options
  static const List<String> ageGroups = [
    '13-17',
    '18-24',
    '25-34',
    '35-44',
    '45-54',
    '55+'
  ];

  // Sports options
  static const List<String> sports = [
    'Football',
    'Basketball',
    'Soccer',
    'Tennis',
    'Baseball',
    'Swimming',
    'Running',
    'Cycling',
    'Golf',
    'Boxing',
    'Cricket',
    'Volleyball',
    'Hockey',
    'Rugby',
    'Badminton',
    'Track & Field',
    'Gymnastics',
    'Wrestling',
    'Martial Arts',
    'Skateboarding'
  ];

  // Interest options
  static const List<String> interests = [
    'Playing Sports',
    'Watching Sports',
    'Sports News',
    'Fantasy Sports',
    'Sports Analytics',
    'Fitness Training',
    'Sports Photography',
    'Sports Betting',
    'Coaching',
    'Sports Equipment',
    'Sports Medicine',
    'Sports Nutrition'
  ];

  // Country options
  static const List<String> countries = [
    'United States',
    'Canada',
    'United Kingdom',
    'Australia',
    'Germany',
    'France',
    'Spain',
    'Italy',
    'Japan',
    'South Korea',
    'India',
    'Brazil',
    'Mexico',
    'Argentina',
    'Netherlands',
    'Sweden',
    'Norway',
    'Denmark',
    'Belgium',
    'Switzerland',
    'Austria',
    'Portugal',
    'Ireland',
    'New Zealand'
  ];

  // Validation messages
  static const String nameRequiredMessage = 'Please enter your name';
  static const String emailRequiredMessage = 'Please enter your email';
  static const String emailInvalidMessage = 'Please enter a valid email';
  static const String passwordRequiredMessage = 'Please enter your password';
  static const String passwordLengthMessage =
      'Password must be at least 6 characters';
  static const String confirmPasswordMessage = 'Please confirm your password';
  static const String passwordMismatchMessage = 'Passwords do not match';
  static const String genderRequiredMessage = 'Please select your gender';
  static const String ageGroupRequiredMessage = 'Please select your age group';
  static const String sportsRequiredMessage =
      'Please select at least one sport';
  static const String interestsRequiredMessage =
      'Please select at least one interest';
  static const String countryRequiredMessage = 'Please select your country';
  static const String userTypeRequiredMessage = 'Please select your user type';

  // UI Text
  static const String joinSportsIN = 'Join SportsIN';
  static const String createProfileSubtitle =
      'Create your sports profile and connect with fellow athletes';
  static const String createProfileButton = 'Create My Sports Profile';
  static const String orRegisterWith = 'Or register with';
  static const String continueWithGoogle = 'Continue with Google';
  static const String alreadyHaveAccount = 'Already have an account?';
  static const String login = 'Login';

  // User Type UI Text
  static const String selectUserType = 'I am a...';
  static const String playerLabel = 'Player';
  static const String recruiterLabel = 'Recruiter';
  static const String playerDescription =
      'I want to showcase my sports skills and connect with teams';
  static const String recruiterDescription =
      'I want to discover and recruit talented athletes';
  static const String registerAsPlayer = 'Register as Player';
  static const String registerAsRecruiter = 'Register as Recruiter';
  static const String loginAsPlayer = 'Login as Player';
  static const String loginAsRecruiter = 'Login as Recruiter';
  static const String createPlayerProfile = 'Create Player Profile';
  static const String createRecruiterProfile = 'Create Recruiter Profile';

  // Section titles and subtitles
  static const String genderTitle = 'Gender';
  static const String ageGroupTitle = 'Age Group';
  static const String sportsTitle = 'Sports Interests';
  static const String sportsSubtitle =
      'Select the sports you play or follow (choose multiple)';
  static const String interestsTitle = 'General Interests';
  static const String interestsSubtitle =
      'What aspects of sports interest you most? (choose multiple)';
  static const String countryTitle = 'Country';
  static const String yourSelectionsTitle = 'Your Selections';

  // Toast Messages
  static const String registrationSuccessMessage =
      'Registration successful! Welcome to SportsIN 🎉';
  static const String registrationProcessingMessage =
      'Creating your sports profile...';

  // Recruiter-specific constants
  static const List<String> organizationTypes = [
    'Professional Team',
    'College/University',
    'High School',
    'Youth Club',
    'Sports Academy',
    'Training Center',
    'Talent Agency',
    'Sports Management Company',
    'Other'
  ];

  static const List<String> recruitmentFocus = [
    'Professional Athletes',
    'College Athletes',
    'High School Athletes',
    'Youth Athletes',
    'Amateur Athletes',
    'Coaches',
    'Support Staff'
  ];

  // Additional section titles
  static const String userTypeTitle = 'User Type';
  static const String organizationTitle = 'Organization';
  static const String organizationTypeTitle = 'Organization Type';
  static const String recruitmentFocusTitle = 'Recruitment Focus';
  static const String organizationSubtitle = 'Tell us about your organization';
  static const String recruitmentFocusSubtitle =
      'What type of talent are you looking for?';
}
