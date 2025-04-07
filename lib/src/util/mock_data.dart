// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import '../models/article.dart';

/// Provides mock data for development and testing of the Galaxy Brain annotation system
class MockData {
  static Future<List<Article>> getSampleArticles() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    return [
      Article(
        id: 'survival-skills',
        title: 'Essential Wilderness Survival Skills',
        content: '''
Wilderness survival skills are vital knowledge for emergency preparedness. This article covers the key areas of survival: shelter, water, fire, and food.

## Shelter
Your first priority in a wilderness survival situation should be shelter. Exposure to the elements can lead to hypothermia or heat exhaustion within hours. Learn to create simple shelters using natural materials like branches, leaves, and debris. A basic lean-to or debris hut can provide sufficient protection until help arrives.

## Water
The human body can survive only about three days without water. Finding and purifying water is critical. Look for water in low-lying areas, valleys, and around green vegetation. Always purify water using boiling, filtration, or chemical treatments to remove harmful pathogens.

## Fire
Fire provides warmth, light, a way to purify water, and a means to cook food. Master multiple fire-starting methods including friction-based techniques, fire steels, magnification, and matches/lighters. Understanding proper fire placement and construction is equally important for safety and efficiency.

## Food
While you can survive several weeks without food, maintaining energy levels is important for other survival tasks. Familiarize yourself with edible plants in various environments, basic trapping techniques, and fishing methods. Focus on calorie-dense food sources that require minimal energy to obtain.

Remember that knowledge, practiced skills, and a calm mindset are your most valuable survival tools.
''',
      ),
      Article(
        id: 'water-purification',
        title: 'Water Purification Methods',
        content: '''
Access to clean water is essential for survival in any scenario. This comprehensive guide covers various water purification methods for emergency situations.

## Boiling
Boiling is one of the most reliable methods to purify water. Bring water to a rolling boil for at least 1 minute (3 minutes at elevations above 6,500 feet) to kill most pathogens. While this method doesn't remove chemical contaminants, it effectively eliminates biological threats.

## Filtration
Physical filtration removes contaminants by passing water through a material with tiny pores. Commercial filters often use ceramic, activated carbon, or fibrous materials to trap particles and some microorganisms. Improvised filters can be created using layers of cloth, sand, charcoal, and gravel.

## Chemical Treatment
Common chemical treatments include:
- Chlorine tablets or liquid (household bleach with 6% sodium hypochlorite, unscented)
- Iodine tablets or solution
- Potassium permanganate

Follow specific dosage instructions based on the chemical used and water volume.

## Solar Disinfection (SODIS)
Fill clear plastic bottles with water and expose them to direct sunlight for at least 6 hours (or 2 days if cloudy). UV-A radiation and heat work together to kill pathogens.

## Distillation
Distillation involves evaporating water and then collecting the condensed vapor. This method removes both biological and many chemical contaminants but requires more equipment and energy.

Knowledge of multiple purification methods provides redundancy for emergency situations when one approach might not be available or practical.
''',
      ),
      Article(
        id: 'edible-plants',
        title: 'Identifying Common Edible Plants',
        content: '''
Foraging for edible plants can provide critical nutrition in survival situations. This guide covers identification principles and common edible plants found in North American regions.

## Universal Edibility Test
Before consuming any unfamiliar plant, and only if necessary:
1. Separate the plant into parts (leaves, stems, roots)
2. Smell the plant part for strong or unpleasant odors
3. Place a small portion on the outside of your lip for 3 minutes to check for burning/itching
4. If no reaction, place on tongue for 15 minutes
5. If still no reaction, chew a small amount but don't swallow for 15 minutes
6. If no reaction, swallow and wait 8 hours before consuming more

Note: This test is not foolproof and should only be used in true survival situations.

## Common Edible Plants

### Dandelion (Taraxacum officinale)
- Identification: Toothed leaves in a basal rosette, hollow stems with milky sap, and yellow flower heads that turn into spherical seed heads
- Edible parts: Entire plant is edible—leaves, flowers, and roots
- Preparation: Young leaves can be eaten raw; older leaves may be boiled to reduce bitterness

### Cattail (Typha spp.)
- Identification: Tall marsh plants with long, flat leaves and distinctive brown cylindrical flower spikes
- Edible parts: Young shoots, pollen, rhizomes (roots)
- Preparation: Young shoots eaten raw or cooked; rhizomes can be peeled and the starchy core eaten or processed into flour

### Pine (Pinus spp.)
- Identification: Evergreen tree with needle-like leaves in bundles and woody cones
- Edible parts: Inner bark (cambium layer), pine nuts, needles
- Preparation: Inner bark can be dried and ground into flour; needles can be steeped for tea

Remember that proper identification is crucial as many edible plants have toxic look-alikes. When possible, learn from experts and consult multiple field guides before foraging.
''',
      ),
      Article(
        id: 'emergency-communication',
        title: 'Emergency Communication Methods',
        content: '''
Effective communication during emergencies can be the difference between life and death. This article explores various methods for signaling and communicating when conventional systems are unavailable.

## Visual Signals
### Signal Mirror
A signal mirror can be seen for miles on a sunny day. To use:
1. Hold the mirror close to your face
2. Create a "V" with your fingers and sight through it at your target
3. Move the mirror so the reflected light passes through your fingers
4. Flash three times (SOS) repeatedly

### Signal Fire
Create three fires in a triangle or straight line, spaced about 100 feet apart. Use green vegetation or damp materials to create smoke during the day.

### Ground-to-Air Signals
Create large symbols visible from the air:
- V = Require assistance
- X = Require medical assistance
- → = Proceeding in this direction
- ↓ = Require medical supplies

## Audio Signals
Use three of anything (whistles, gunshots, etc.) spaced evenly apart as a universal distress signal. Repeat after a pause.

## Radio Communication
### Ham Radio
Amateur (ham) radio operators can communicate globally and are often active during disasters. Learning basic operations and obtaining a license is relatively simple.

### Citizen Band (CB) Radio
CB radios don't require licenses and have a range of 1-5 miles normally, potentially further in optimal conditions.

## Improvised Communication
### Message Relay
In populated areas, sending messages with multiple people can create a human relay system.

### Trail Marking
Create directional markers with rocks, sticks, or other materials to indicate your movement or leave messages for rescuers.

Practicing these skills before emergencies will improve effectiveness when they're needed most.
''',
      ),
      Article(
        id: 'knowledge-preservation',
        title: 'Methods of Knowledge Preservation in Grid-Down Scenarios',
        content: '''
Preserving knowledge during extended grid-down scenarios is vital for rebuilding society and maintaining technological progress. This article examines practical approaches to knowledge preservation when digital systems are unavailable.

## Physical Media Storage
### Printed Materials
High-quality acid-free paper books remain one of the most durable and accessible knowledge storage methods. Consider:
- Technical manuals for essential systems (water purification, construction, medicine)
- Agricultural references
- General encyclopedias
- Локальные знания specific to your region

Store printed materials in waterproof, airtight containers with desiccants to prevent moisture damage.

### Microfilm and Microfiche
These formats can store vast amounts of information in a compact, physical form that requires only magnification to read. They're durable when properly stored and can last centuries.

## Knowledge Redundancy
### Community Knowledge Banks
Establish community knowledge repositories where multiple copies of critical information are stored in different locations. This prevents single-point failures from destroying valuable knowledge.

### Skill Preservation Through Teaching
Implement apprenticeship programs where each skilled individual trains multiple others. This "living knowledge" approach ensures critical skills survive even if documentation is lost.

## Low-Tech Knowledge Systems
### Clay Tablets
One of humanity's oldest recording methods, clay tablets can survive for thousands of years when properly fired.

### Oral Traditions
Structured memorization systems like those used by ancient cultures can preserve detailed information through generations. Stories, rhymes, and songs make knowledge memorable and transferable.

## Recovery Planning
Create "bootstrap documents" that contain the fundamental knowledge needed to rebuild more complex systems. These would include basic principles of science, mathematics, and engineering that could help future generations recover lost technology.

Remember that diversification is key—no single preservation method is foolproof. Implementing multiple approaches provides the best chance for knowledge to survive through extended crises.
''',
      ),
    ];
  }
  
  static String getRawContent(Article article) {
    // In a real implementation, this would return the raw ZIM content
    // For mock purposes, we'll just return HTML-formatted content
    return '''
<!DOCTYPE html>
<html>
<head>
  <title>${article.title}</title>
</head>
<body>
  <h1>${article.title}</h1>
  <article>
    ${article.content.replaceAll('\n\n## ', '\n\n<h2>').replaceAll('\n\n### ', '\n\n<h3>').replaceAll('\n\n', '\n\n<p>').replaceAll('</h3>\n\n<p>', '</h3>\n\n').replaceAll('</h2>\n\n<p>', '</h2>\n\n')}
  </article>
</body>
</html>
''';
  }
}
