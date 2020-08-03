/*
 *    This program is free software; you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation; either version 2 of the License, or
 *    (at your option) any later version.
 *
 *    This program is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with this program; if not, write to the Free Software
 *    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

/*
 *    SaveDataToDbIncremental.java
 *    Copyright (C) 2009 University of Waikato, Hamilton, New Zealand
 *
 */

package wekaexamples.core.converters;

import weka.core.Instance;
import weka.core.Instances;
import weka.core.converters.DatabaseLoader;
import weka.core.converters.DatabaseSaver;

/**
 * Loads data from a JDBC database using the
 * weka.core.converters.DatabaseLoader class and saves it to another JDBC
 * database using the weka.core.converters.DatabaseSaver class. The data is
 * loaded/saved incrementally.
 *
 * @author FracPete (fracpete at waikato dot ac dot nz)
 * @version $Revision: 5628 $
 */
public class SaveDataToDbIncremental {

  /**
   * Expects no parameters.
   *
   * @param args        the command-line parameters
   * @throws Exception  if something goes wrong
   */
  public static void main(String[] args) throws Exception {
    // output usage
    if (args.length != 0) {
      System.err.println("\nUsage: java SaveDataToDbBatch\n");
      System.exit(1);
    }

    System.out.println("\nReading data...");
    DatabaseLoader loader = new DatabaseLoader();
    loader.setSource("jdbc_url", "the_user", "the_password");
    loader.setQuery("select * from whatsoever");
    // it might be necessary to define the columns that uniquely identify
    // a single row. Just provide them as comma-separated list:
    // loader.setKeys("col1,col2,...");
    Instances structure = loader.getStructure();
    Instances data = new Instances(structure);
    Instance inst;
    int count = 0;
    while ((inst = loader.getNextInstance(structure)) != null) {
      data.add(inst);
      count++;
      if ((count % 100) == 0)
        System.out.println(count + " rows read so far.");
    }

    System.out.println("\nSaving data...");
    DatabaseSaver saver = new DatabaseSaver();
    saver.setDestination("jdbc_url", "the_user", "the_password");
    // we explicitly specify the table name here:
    saver.setTableName("whatsoever2");
    saver.setRelationForTableName(false);
    // or we could just update the name of the dataset:
    // saver.setRelationForTableName(true);
    // data.setRelationName("whatsoever2");
    saver.setRetrieval(DatabaseSaver.INCREMENTAL);
    saver.setStructure(data);
    count = 0;
    for (int i = 0; i < data.numInstances(); i++) {
      saver.writeIncremental(data.instance(i));
      count++;
      if ((count % 100) == 0)
        System.out.println(count + " rows written so far.");
    }
    // notify saver that we're done
    saver.writeIncremental(null);
  }
}
