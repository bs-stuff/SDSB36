-- SB 36 Engagement Tracking Table
-- Run this in your Supabase SQL Editor

CREATE TABLE sb36_engagement (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    district INTEGER NOT NULL DEFAULT 0,
    bill_number TEXT NOT NULL DEFAULT 'SB 36',
    stance TEXT NOT NULL DEFAULT 'oppose',
    template_name TEXT NOT NULL,
    action_type TEXT NOT NULL CHECK (action_type IN ('email', 'copy')),
    legislator_name TEXT,
    legislator_chamber TEXT CHECK (legislator_chamber IN ('Senate', 'House', NULL)),
    contact_mode TEXT CHECK (contact_mode IN ('district', 'committee', NULL)),
    agency TEXT
);

-- Create indexes for common queries
CREATE INDEX idx_sb36_engagement_district ON sb36_engagement(district);
CREATE INDEX idx_sb36_engagement_created ON sb36_engagement(created_at DESC);
CREATE INDEX idx_sb36_engagement_template ON sb36_engagement(template_name);
CREATE INDEX idx_sb36_engagement_contact_mode ON sb36_engagement(contact_mode);

-- Enable Row Level Security
ALTER TABLE sb36_engagement ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can insert (for tracking)
CREATE POLICY "Allow anonymous inserts" ON sb36_engagement
    FOR INSERT TO anon
    WITH CHECK (true);

-- Policy: Only authenticated users can read (for your dashboard)
CREATE POLICY "Allow authenticated reads" ON sb36_engagement
    FOR SELECT TO authenticated
    USING (true);

-- Useful views for analytics

-- Engagement by district
CREATE OR REPLACE VIEW sb36_engagement_by_district AS
SELECT
    district,
    COUNT(*) as total_actions,
    COUNT(*) FILTER (WHERE action_type = 'email') as emails_sent,
    COUNT(DISTINCT template_name) as templates_used
FROM sb36_engagement
GROUP BY district
ORDER BY total_actions DESC;

-- Engagement by template (reason for position)
CREATE OR REPLACE VIEW sb36_engagement_by_template AS
SELECT
    template_name,
    COUNT(*) as times_used,
    COUNT(DISTINCT district) as districts_using,
    COUNT(DISTINCT agency) FILTER (WHERE agency IS NOT NULL) as unique_agencies
FROM sb36_engagement
GROUP BY template_name
ORDER BY times_used DESC;

-- Engagement by contact mode
CREATE OR REPLACE VIEW sb36_engagement_by_mode AS
SELECT
    contact_mode,
    COUNT(*) as total_actions,
    COUNT(DISTINCT district) as unique_districts,
    COUNT(DISTINCT legislator_name) as legislators_contacted
FROM sb36_engagement
GROUP BY contact_mode
ORDER BY total_actions DESC;

-- Engagement by agency
CREATE OR REPLACE VIEW sb36_engagement_by_agency AS
SELECT
    COALESCE(agency, 'Individual') as agency,
    COUNT(*) as total_actions,
    COUNT(DISTINCT legislator_name) as legislators_contacted,
    COUNT(DISTINCT template_name) as templates_used
FROM sb36_engagement
GROUP BY agency
ORDER BY total_actions DESC;

-- Daily engagement summary
CREATE OR REPLACE VIEW sb36_engagement_daily AS
SELECT
    DATE(created_at) as date,
    COUNT(*) as total_actions,
    COUNT(DISTINCT district) as unique_districts,
    COUNT(DISTINCT agency) FILTER (WHERE agency IS NOT NULL) as unique_agencies
FROM sb36_engagement
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- Committee vs District outreach
CREATE OR REPLACE VIEW sb36_engagement_committee_impact AS
SELECT
    legislator_name,
    legislator_chamber,
    COUNT(*) as times_contacted,
    COUNT(DISTINCT template_name) as unique_messages,
    COUNT(DISTINCT agency) FILTER (WHERE agency IS NOT NULL) as unique_agencies
FROM sb36_engagement
WHERE legislator_name IS NOT NULL
GROUP BY legislator_name, legislator_chamber
ORDER BY times_contacted DESC;

-- Grant access to views for authenticated users
GRANT SELECT ON sb36_engagement_by_district TO authenticated;
GRANT SELECT ON sb36_engagement_by_template TO authenticated;
GRANT SELECT ON sb36_engagement_by_mode TO authenticated;
GRANT SELECT ON sb36_engagement_by_agency TO authenticated;
GRANT SELECT ON sb36_engagement_daily TO authenticated;
GRANT SELECT ON sb36_engagement_committee_impact TO authenticated;
