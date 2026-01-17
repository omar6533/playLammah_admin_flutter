import {
  collection,
  doc,
  getDocs,
  getDoc,
  addDoc,
  updateDoc,
  deleteDoc,
  query,
  where,
  orderBy,
  Timestamp,
  writeBatch,
  getCountFromServer
} from 'firebase/firestore';
import { db } from './firebase';

export interface MainCategory {
  id: string;
  name_ar: string;
  display_order: number;
  is_active: boolean;
  status: 'active' | 'disabled';
  media_url?: string;
  created_at: Date;
  updated_at: Date;
}

export interface SubCategory {
  id: string;
  main_category_id: string;
  name_ar: string;
  display_order: number;
  is_active: boolean;
  media_url: string;
  created_at: Date;
  updated_at: Date;
  main_categories?: {
    name_ar: string;
  };
}

export interface Question {
  id: string;
  sub_category_id: string;
  question_text_ar: string;
  answer_text_ar: string;
  question_media_url?: string;
  answer_media_url?: string;
  points: number;
  status: 'active' | 'disabled' | 'draft';
  created_at: Date;
  updated_at: Date;
  sub_categories?: {
    name_ar: string;
    main_category_id: string;
    main_categories?: {
      name_ar: string;
    };
  };
}

export interface Game {
  id: string;
  status: 'waiting' | 'in_progress' | 'completed';
  created_at: Date;
  started_at?: Date;
  completed_at?: Date;
}

export interface GamePlayer {
  id: string;
  game_id: string;
  user_id: string;
  player_name: string;
  score: number;
  position: number;
}

export interface Payment {
  id: string;
  user_id: string;
  amount: number;
  currency: string;
  status: 'pending' | 'completed' | 'failed';
  payment_method: string;
  created_at: Date;
}

export interface User {
  id: string;
  email: string;
  display_name?: string;
  created_at: Date;
}

export type Category = MainCategory;

const convertFirestoreDoc = (docSnap: any): any => {
  const data = docSnap.data();
  return {
    id: docSnap.id,
    ...data,
    created_at: data.created_at?.toDate() || new Date(),
    updated_at: data.updated_at?.toDate() || new Date(),
    started_at: data.started_at?.toDate(),
    completed_at: data.completed_at?.toDate(),
  };
};

export const mainCategoriesApi = {
  async getAll() {
    const q = query(collection(db, 'main_categories'), orderBy('display_order', 'asc'));
    const snapshot = await getDocs(q);
    return snapshot.docs.map(convertFirestoreDoc) as MainCategory[];
  },

  async create(category: Omit<MainCategory, 'id' | 'created_at' | 'updated_at'>) {
    const now = Timestamp.now();
    const docRef = await addDoc(collection(db, 'main_categories'), {
      ...category,
      created_at: now,
      updated_at: now,
    });
    const docSnap = await getDoc(docRef);
    return convertFirestoreDoc(docSnap) as MainCategory;
  },

  async update(id: string, updates: Partial<MainCategory>) {
    const docRef = doc(db, 'main_categories', id);
    await updateDoc(docRef, {
      ...updates,
      updated_at: Timestamp.now(),
    });
    const docSnap = await getDoc(docRef);
    return convertFirestoreDoc(docSnap) as MainCategory;
  },

  async delete(id: string) {
    await deleteDoc(doc(db, 'main_categories', id));
  }
};

export const subCategoriesApi = {
  async getAll(mainCategoryId?: string) {
    let q = query(collection(db, 'sub_categories'), orderBy('display_order', 'asc'));

    if (mainCategoryId) {
      q = query(collection(db, 'sub_categories'),
        where('main_category_id', '==', mainCategoryId),
        orderBy('display_order', 'asc'));
    }

    const snapshot = await getDocs(q);
    const subCategories = snapshot.docs.map(convertFirestoreDoc) as SubCategory[];

    const mainCategoryIds = [...new Set(subCategories.map(sc => sc.main_category_id))];
    const mainCategories = new Map<string, MainCategory>();

    for (const mcId of mainCategoryIds) {
      const mcDoc = await getDoc(doc(db, 'main_categories', mcId));
      if (mcDoc.exists()) {
        mainCategories.set(mcId, convertFirestoreDoc(mcDoc));
      }
    }

    return subCategories.map(sc => ({
      ...sc,
      main_categories: mainCategories.get(sc.main_category_id)
        ? { name_ar: mainCategories.get(sc.main_category_id)!.name_ar }
        : undefined
    }));
  },

  async create(subCategory: Omit<SubCategory, 'id' | 'created_at' | 'updated_at' | 'main_categories'>) {
    const now = Timestamp.now();
    const docRef = await addDoc(collection(db, 'sub_categories'), {
      ...subCategory,
      created_at: now,
      updated_at: now,
    });
    const docSnap = await getDoc(docRef);
    return convertFirestoreDoc(docSnap) as SubCategory;
  },

  async update(id: string, updates: Partial<SubCategory>) {
    const docRef = doc(db, 'sub_categories', id);
    await updateDoc(docRef, {
      ...updates,
      updated_at: Timestamp.now(),
    });
    const docSnap = await getDoc(docRef);
    return convertFirestoreDoc(docSnap) as SubCategory;
  },

  async delete(id: string) {
    await deleteDoc(doc(db, 'sub_categories', id));
  }
};

export const categoriesApi = mainCategoriesApi;

export const questionsApi = {
  async getAll(filters?: { mainCategoryId?: string; subCategoryId?: string; points?: number; status?: string; search?: string }) {
    let q = query(collection(db, 'questions'), orderBy('created_at', 'desc'));

    if (filters?.subCategoryId) {
      q = query(collection(db, 'questions'),
        where('sub_category_id', '==', filters.subCategoryId),
        orderBy('created_at', 'desc'));
    }
    if (filters?.points) {
      q = query(collection(db, 'questions'),
        where('points', '==', filters.points),
        orderBy('created_at', 'desc'));
    }
    if (filters?.status) {
      q = query(collection(db, 'questions'),
        where('status', '==', filters.status),
        orderBy('created_at', 'desc'));
    }

    const snapshot = await getDocs(q);
    let results = snapshot.docs.map(convertFirestoreDoc) as Question[];

    const subCategoryIds = [...new Set(results.map(r => r.sub_category_id))];
    const subCategories = new Map<string, SubCategory>();
    const mainCategories = new Map<string, MainCategory>();

    for (const scId of subCategoryIds) {
      const scDoc = await getDoc(doc(db, 'sub_categories', scId));
      if (scDoc.exists()) {
        const sc = convertFirestoreDoc(scDoc);
        subCategories.set(scId, sc);

        const mcDoc = await getDoc(doc(db, 'main_categories', sc.main_category_id));
        if (mcDoc.exists()) {
          mainCategories.set(sc.main_category_id, convertFirestoreDoc(mcDoc));
        }
      }
    }

    results = results.map(q => {
      const subCat = subCategories.get(q.sub_category_id);
      const mainCat = subCat ? mainCategories.get(subCat.main_category_id) : undefined;
      return {
        ...q,
        sub_categories: subCat ? {
          name_ar: subCat.name_ar,
          main_category_id: subCat.main_category_id,
          main_categories: mainCat ? { name_ar: mainCat.name_ar } : undefined
        } : undefined
      };
    });

    if (filters?.mainCategoryId) {
      results = results.filter(q =>
        q.sub_categories?.main_category_id === filters.mainCategoryId
      );
    }

    if (filters?.search) {
      const searchLower = filters.search.toLowerCase();
      results = results.filter(q =>
        q.question_text_ar.toLowerCase().includes(searchLower) ||
        q.answer_text_ar.toLowerCase().includes(searchLower)
      );
    }

    return results;
  },

  async getBySubCategory(subCategoryId: string) {
    const q = query(
      collection(db, 'questions'),
      where('sub_category_id', '==', subCategoryId),
      orderBy('points', 'asc')
    );
    const snapshot = await getDocs(q);
    const questions = snapshot.docs.map(convertFirestoreDoc) as Question[];

    const scDoc = await getDoc(doc(db, 'sub_categories', subCategoryId));
    if (scDoc.exists()) {
      const subCat = convertFirestoreDoc(scDoc);
      return questions.map(q => ({
        ...q,
        sub_categories: { name_ar: subCat.name_ar }
      }));
    }

    return questions;
  },

  async checkDuplicate(subCategoryId: string, points: number, excludeId?: string) {
    const q = query(
      collection(db, 'questions'),
      where('sub_category_id', '==', subCategoryId),
      where('points', '==', points)
    );
    const snapshot = await getDocs(q);

    if (excludeId) {
      return snapshot.docs.some(doc => doc.id !== excludeId);
    }

    return !snapshot.empty;
  },

  async create(question: Omit<Question, 'id' | 'created_at' | 'updated_at' | 'sub_categories'>) {
    const duplicate = await this.checkDuplicate(question.sub_category_id, question.points);
    if (duplicate) {
      throw new Error(`A question with ${question.points} points already exists for this sub-category`);
    }

    const now = Timestamp.now();
    const docRef = await addDoc(collection(db, 'questions'), {
      ...question,
      created_at: now,
      updated_at: now,
    });
    const docSnap = await getDoc(docRef);
    return convertFirestoreDoc(docSnap) as Question;
  },

  async update(id: string, updates: Partial<Question>) {
    if (updates.sub_category_id && updates.points) {
      const duplicate = await this.checkDuplicate(updates.sub_category_id, updates.points, id);
      if (duplicate) {
        throw new Error(`A question with ${updates.points} points already exists for this sub-category`);
      }
    }

    const docRef = doc(db, 'questions', id);
    await updateDoc(docRef, {
      ...updates,
      updated_at: Timestamp.now(),
    });
    const docSnap = await getDoc(docRef);
    return convertFirestoreDoc(docSnap) as Question;
  },

  async delete(id: string) {
    await deleteDoc(doc(db, 'questions', id));
  }
};

export const gamesApi = {
  async getAll() {
    const q = query(collection(db, 'games'), orderBy('created_at', 'desc'));
    const snapshot = await getDocs(q);
    return snapshot.docs.map(convertFirestoreDoc) as Game[];
  },

  async getPlayers(gameId: string) {
    const q = query(
      collection(db, 'game_players'),
      where('game_id', '==', gameId),
      orderBy('score', 'desc')
    );
    const snapshot = await getDocs(q);
    return snapshot.docs.map(convertFirestoreDoc) as GamePlayer[];
  }
};

export const paymentsApi = {
  async getAll() {
    const q = query(collection(db, 'payments'), orderBy('created_at', 'desc'));
    const snapshot = await getDocs(q);
    return snapshot.docs.map(convertFirestoreDoc) as Payment[];
  }
};

export const usersApi = {
  async getAll() {
    const q = query(collection(db, 'users'), orderBy('created_at', 'desc'));
    const snapshot = await getDocs(q);
    return snapshot.docs.map(convertFirestoreDoc) as User[];
  }
};

export const statsApi = {
  async getDashboardStats() {
    const [
      mainCategoriesCount,
      subCategoriesCount,
      questionsCount,
      activeQuestionsSnapshot,
      gamesCount,
      usersCount
    ] = await Promise.all([
      getCountFromServer(collection(db, 'main_categories')),
      getCountFromServer(collection(db, 'sub_categories')),
      getCountFromServer(collection(db, 'questions')),
      getDocs(query(collection(db, 'questions'), where('status', '==', 'active'))),
      getCountFromServer(collection(db, 'games')),
      getCountFromServer(collection(db, 'users'))
    ]);

    return {
      totalMainCategories: mainCategoriesCount.data().count,
      totalSubCategories: subCategoriesCount.data().count,
      totalQuestions: questionsCount.data().count,
      activeQuestions: activeQuestionsSnapshot.size,
      totalGames: gamesCount.data().count,
      totalUsers: usersCount.data().count
    };
  }
};

export type { MainCategory as Category };
