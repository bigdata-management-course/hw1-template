package edu.univ.haifa.bigdata.hw1;

import org.apache.hadoop.util.ProgramDriver;

/** Entry point: hadoop jar hw1.jar &lt;task&gt; [-D key=value ...] args... */
public class Hw1 {

    public static void main(String[] args) throws Throwable {
        ProgramDriver pd = new ProgramDriver();
        pd.addClass("project-views", ProjectViews.class, "Task 1: total views per project code");
        pd.addClass("hourly-profile", HourlyProfile.class, "Task 2: desktop/mobile views per language and hour");
        pd.addClass("language-join", LanguageJoin.class, "Task 3: join language totals with languages.tsv");
        pd.addClass("top-pages", TopPages.class, "Task 4: top-K pages per language");
        System.exit(pd.run(args));
    }
}
