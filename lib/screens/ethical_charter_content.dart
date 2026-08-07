// GENERATED from FINIX_Ethical_AI_Charter.md.docx — do not edit by hand.
//
// The Word document is the source of truth. It is rendered natively rather
// than shipped as a file so it inherits the app theme, stays readable on a
// device with no document viewer, and can be searched and scaled like any
// other screen.

/// One rendered element of the charter.
class CharterBlock {
  const CharterBlock.heading(this.text) : kind = CharterKind.heading;
  const CharterBlock.body(this.text) : kind = CharterKind.body;
  const CharterBlock.bullet(this.text) : kind = CharterKind.bullet;

  final CharterKind kind;
  final String text;
}

enum CharterKind { heading, body, bullet }

const List<CharterBlock> ethicalCharterDocument = [
  CharterBlock.heading('FINIX Twin — Ethical AI Charter'),
  CharterBlock.heading('Version: 1.0 Effective Date: [02 August 2026]'),
  CharterBlock.body('Applicable Law & Regulatory Basis: Digital Personal Data Protection Act, 2023 and Digital'),
  CharterBlock.body('Personal Data Protection Rules, 2025 (Ministry of Electronics and Information'),
  CharterBlock.body('Technology); Reserve Bank of India — Framework for Responsible and Ethical Enablement of Artificial Intelligence ("FREE-AI", August 2025); RBI Fair Practices Code; RBI Digital Lending Directions, 2025 (as applicable to lending/credit-linked features)'),
  CharterBlock.body('This Charter is a binding internal governance document and a public-facing commitment. It is available to every user inside Help & Support → Ethical AI Charter and is reviewed at least annually by the Product Ethics Team or on any material regulatory change, whichever is sooner. Purpose and Scope'),
  CharterBlock.body('This Charter governs every AI/ML-driven feature in the FINIX Twin application — including transaction risk scoring, fraud and phishing detection, investment and product recommendations, the Financial Health Score, nudges, and any conversational or "twin" assistant — from design, through deployment, to ongoing monitoring and retirement.'),
  CharterBlock.heading('It applies to:'),
  CharterBlock.body('All internal teams (product, engineering, data science, risk, compliance) building or operating AI features.'),
  CharterBlock.body('All third-party vendors, model providers, and outsourced service providers ("Lending Service Providers" or equivalent) integrated into FINIX Twin.'),
  CharterBlock.body('Every user of the FINIX Twin application, who is the intended beneficiary of these commitments.'),
  CharterBlock.body('Where any provision of this Charter is inconsistent with applicable law or a binding RBI direction, the law or direction prevails, and this Charter will be updated accordingly.'),
  CharterBlock.heading('Core Principles'),
  CharterBlock.heading('Transparency and Explainability at Every Step'),
  CharterBlock.body('No AI-driven decision that materially affects a user\'s financial experience — a blocked transaction, an investment recommendation, a change to the Financial Health Score, a credit or risk decision — is presented without a plain-language explanation identifying the data and logic that drove the outcome. Explanations are written for a lay user, not a'),
  CharterBlock.body('technical audience, consistent with FREE-AI\'s explainability expectations for regulated entities.'),
  CharterBlock.body('Where FINIX Twin uses a voice or chat-based AI assistant, the assistant identifies itself as an automated system at the start of the interaction and discloses when a human agent has taken over.'),
  CharterBlock.heading('No Guaranteed Returns'),
  CharterBlock.body('AI-generated content relating to financial outcomes uses only qualified language — "projected," "estimated," "simulated," "may," "historically" — and never asserts certainty of outcome. The word "guaranteed" is programmatically blocked from appearing in any AIgenerated output relating to returns, income, or performance. FINIX Twin does not hold itself out as providing regulated investment advice unless it is separately licensed and disclosed to do so, and all AI outputs carry appropriate risk disclaimers.'),
  CharterBlock.heading('No Dark Patterns'),
  CharterBlock.body('FINIX Twin does not deploy manipulative interface patterns in connection with any AI feature, including but not limited to: fabricated urgency or countdown timers, pre-ticked consent or subscription boxes, colour or iconography designed to mislead risk perception, or framing that understates fees, risk, or the consequences of a decision. Every AI-surfaced UI element states exactly what it does and no more.'),
  CharterBlock.heading('Consent-First Data Use'),
  CharterBlock.body('Personal and financial data is processed by AI systems strictly for the purposes to which the user has given free, specific, informed, unconditional, and unambiguous consent, in line with the DPDP Act, 2023. There is no inferred or bundled consent. Specifically:'),
  CharterBlock.body('Consent requests are presented in clear, itemised language, independent of consent for unrelated processing, and available in English and applicable regional languages.'),
  CharterBlock.body('Users can withdraw consent at any time through a mechanism as easy to use as the one used to give consent, and FINIX Twin will explain the practical consequences of withdrawal (e.g., which features will stop working) before the withdrawal is confirmed.'),
  CharterBlock.body('Personal data is retained only as long as necessary for the stated purpose or as required by law, after which it is erased in accordance with the DPDP Rules, 2025.'),
  CharterBlock.body('A Data Protection Officer / grievance contact is published in-app for all data principal requests (access, correction, erasure, grievance redressal), consistent with DPDP Rules, 2025.'),
  CharterBlock.body('In the event of a personal data breach, affected users and the Data Protection Board of India are notified within the timelines prescribed under the DPDP Rules, 2025.'),
  CharterBlock.heading('Human Override Always Available'),
  CharterBlock.body('AI systems in FINIX Twin recommend and assess; they do not have unilateral final authority over a user\'s money. Specifically:'),
  CharterBlock.body('A transaction blocked by an AI fraud/risk model can always be reviewed and overridden by a verified user through a clear in-app escalation path, subject to identity verification.'),
  CharterBlock.body('An AI-recommended investment or product can always be declined, and declining carries no penalty, hidden cost, or degraded service.'),
  CharterBlock.body('A human-accountable escalation path (support team / grievance officer) is available for any user who disputes an AI-driven outcome, consistent with FREE-AI\'s principle that regulated entities remain accountable for AI decisions regardless of the model\'s autonomy.'),
  CharterBlock.heading('Bias Auditing'),
  CharterBlock.body('AI models underlying the Financial Health Score, nudging, risk scoring, and recommendations are periodically audited for demographic and socioeconomic bias, so that outcomes do not systematically disadvantage users on the basis of income level, gender, age, geography, or other protected characteristics.'),
  CharterBlock.body('Audits are conducted at least quarterly, and additionally before any material model update is deployed to production.'),
  CharterBlock.body('Audit results, methodology, and any corrective action are reviewed and signed off by the Product Ethics Team.'),
  CharterBlock.body('Where an audit identifies material bias, the affected model or feature is remediated or suspended until corrected.'),
  CharterBlock.heading('Fairness in Product Suggestions'),
  CharterBlock.body('AI-driven product recommendations (insurance, investment funds, credit products, or other paid offerings) are generated based solely on assessed user benefit. The system does not disproportionately surface paid products over free or lower-cost alternatives when the free alternative is equally suitable for the user\'s stated goal and risk profile. Any commercial relationship, referral fee, or revenue-share connected to a recommended product is disclosed to the user at the point of recommendation.'),
  CharterBlock.heading('Regulatory Alignment'),
];
