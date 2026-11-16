package edu.univ.haifa.bigdata.hw1;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

/** One line of a Wikimedia pageview dump: "domain_code page_title count_views total_response_size". */
public final class Pageview {

    public enum Counter { MALFORMED }

    private static final Pattern HOUR = Pattern.compile("pageviews-\\d{8}-(\\d{2})0000.*");

    public final String project;
    public final String title;
    public final long views;

    private Pageview(String project, String title, long views) {
        this.project = project;
        this.title = title;
        this.views = views;
    }

    /** Returns null for a malformed line. */
    public static Pageview parse(String line) {
        String[] f = line.split(" ");
        if (f.length != 4) {
            return null;
        }
        try {
            return new Pageview(f[0], f[1], Long.parseLong(f[2]));
        } catch (NumberFormatException e) {
            return null;
        }
    }

    /**
     * Wikipedia language of a project code: "en" (desktop) and "en.m" (mobile) give "en";
     * anything with another suffix (en.d = Wiktionary, commons.m.m, ...) gives null.
     */
    public static String languageOf(String project) {
        int dot = project.indexOf('.');
        if (dot < 0) {
            return project;
        }
        return dot == project.length() - 2 && project.endsWith(".m") ? project.substring(0, dot) : null;
    }

    public String language() {
        return languageOf(project);
    }

    public boolean isMobile() {
        return project.endsWith(".m");
    }

    /** "pageviews-20260915-040000.gz" -> "04"; null if the name does not follow the dump convention. */
    public static String hourOf(String fileName) {
        Matcher m = HOUR.matcher(fileName);
        return m.matches() ? m.group(1) : null;
    }
}
