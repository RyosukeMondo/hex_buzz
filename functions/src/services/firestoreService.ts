/**
 * Firestore service layer
 * Provides abstracted database operations with logging and error handling
 */

import { getFirestore } from "firebase-admin/firestore";
import { Logger } from "../utils/logger";
import { ErrorHandler } from "../utils/errorHandler";

export class FirestoreService {
  private db = getFirestore();

  async getDocument<T>(collection: string, docId: string): Promise<T | null> {
    return ErrorHandler.wrap(async () => {
      Logger.debug("firestore_read", { collection, docId });

      const doc = await this.db.collection(collection).doc(docId).get();

      if (!doc.exists) {
        return null;
      }

      return doc.data() as T;
    }, "getDocument");
  }

  async setDocument<T extends Record<string, any>>(
    collection: string,
    docId: string,
    data: T
  ): Promise<void> {
    return ErrorHandler.wrap(async () => {
      Logger.debug("firestore_write", { collection, docId });
      await this.db.collection(collection).doc(docId).set(data);
    }, "setDocument");
  }

  async updateDocument<T>(
    collection: string,
    docId: string,
    data: Partial<T>
  ): Promise<void> {
    return ErrorHandler.wrap(async () => {
      Logger.debug("firestore_update", { collection, docId });
      await this.db.collection(collection).doc(docId).update(data);
    }, "updateDocument");
  }

  async queryCollection<T>(
    collection: string,
    filters: Array<{ field: string; op: any; value: any }>
  ): Promise<T[]> {
    return ErrorHandler.wrap(async () => {
      Logger.debug("firestore_query", { collection, filters });

      let query: any = this.db.collection(collection);

      for (const filter of filters) {
        query = query.where(filter.field, filter.op, filter.value);
      }

      const snapshot = await query.get();
      return snapshot.docs.map((doc: any) => doc.data() as T);
    }, "queryCollection");
  }

  async queryDocuments<T>(
    collection: string,
    orderBy: Array<{ field: string; direction: "asc" | "desc" }>,
    limit?: number
  ): Promise<T[]> {
    return ErrorHandler.wrap(async () => {
      Logger.debug("firestore_query_ordered", { collection, orderBy, limit });

      let query: any = this.db.collection(collection);

      for (const order of orderBy) {
        query = query.orderBy(order.field, order.direction);
      }

      if (limit) {
        query = query.limit(limit);
      }

      const snapshot = await query.get();
      return snapshot.docs.map((doc: any) => doc.data() as T);
    }, "queryDocuments");
  }

  async documentExists(collection: string, docId: string): Promise<boolean> {
    return ErrorHandler.wrap(async () => {
      const doc = await this.db.collection(collection).doc(docId).get();
      return doc.exists;
    }, "documentExists");
  }

  getDocumentReference(collection: string, docId: string) {
    return this.db.collection(collection).doc(docId);
  }

  getCollectionReference(collection: string) {
    return this.db.collection(collection);
  }
}
